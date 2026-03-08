import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ═══════════════════════════════════════
//  TABLE DEFINITIONS
// ═══════════════════════════════════════

/// Dompet: Digital (Bank) & Tunai (Laci)
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().withDefault(const Constant('Digital'))();
  TextColumn get name => text()();
  RealColumn get balance => real().withDefault(const Constant(0))();
}

/// Layanan transfer (BRI, antar bank, e-wallet, dll)
class Services extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get adminBank => real().withDefault(const Constant(0))();
}

/// Konfigurasi harga admin per range nominal
class PriceConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'Transfer' atau 'Tarik Tunai'
  RealColumn get minNominal => real()();
  RealColumn get maxNominal => real()();
  RealColumn get adminUser => real()();
}

/// Transaksi (Transfer & Tarik Tunai)
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'Transfer', 'Tarik Tunai'
  RealColumn get amount => real()();
  RealColumn get adminBank => real().withDefault(const Constant(0))();
  RealColumn get adminUser => real().withDefault(const Constant(0))();
  RealColumn get profit => real().withDefault(const Constant(0))();
  IntColumn get isPiutang => integer().withDefault(const Constant(0))();
  TextColumn get customerName => text().nullable()();
  IntColumn get walletId => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get receivableId =>
      integer().nullable().references(Receivables, #id)();
}

/// Pengeluaran operasional
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  IntColumn get walletId => integer().withDefault(const Constant(2))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Piutang pelanggan
class Receivables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text()();
  RealColumn get totalDebt => real()();
  TextColumn get status => text()(); // 'Belum Lunas', 'Lunas'
}

/// Log pembayaran piutang
class ReceivableLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receivableId => integer().references(Receivables, #id)();
  RealColumn get amountPaid => real()();
  IntColumn get walletId => integer().withDefault(const Constant(2))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Penyesuaian saldo (Penambahan, Prive, Koreksi, Pindah)
class Adjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type =>
      text()(); // 'Penambahan', 'Tarik Prive', 'Koreksi Minus', 'Pindah Saldo'
  IntColumn get walletId => integer().withDefault(const Constant(1))();
  IntColumn get targetWalletId => integer().nullable()();
  RealColumn get amount => real()();
  RealColumn get fee => real().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Pengaturan aplikasi (key-value store)
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Users (login)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get password => text()();
  TextColumn get role => text().withDefault(const Constant('Kasir'))();
}

// ═══════════════════════════════════════
//  DATABASE CLASS
// ═══════════════════════════════════════

@DriftDatabase(
  tables: [
    Wallets,
    Services,
    PriceConfigs,
    Transactions,
    Expenses,
    Receivables,
    ReceivableLogs,
    Adjustments,
    AppSettings,
    Users,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  /// Singleton instance
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._internal(_openConnection());
    return _instance!;
  }

  /// For testing — allow injecting a custom executor
  factory AppDatabase.forTesting(QueryExecutor e) => AppDatabase._internal(e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultData();
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        try {
          await m.createTable(wallets);
        } catch (_) {}
        try {
          await m.addColumn(transactions, transactions.walletId);
        } catch (_) {}
        try {
          await m.addColumn(expenses, expenses.walletId);
        } catch (_) {}
        try {
          await m.addColumn(receivableLogs, receivableLogs.walletId);
        } catch (_) {}
        try {
          await m.addColumn(adjustments, adjustments.walletId);
        } catch (_) {}
        try {
          await m.addColumn(adjustments, adjustments.targetWalletId);
        } catch (_) {}
      }
      if (from < 4) {
        try {
          await m.addColumn(adjustments, adjustments.fee);
        } catch (_) {}
      }
      if (from < 5) {
        try {
          await m.addColumn(transactions, transactions.receivableId);
        } catch (_) {}
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (!details.wasCreated) {
        try {
          final countResult = await customSelect(
            'SELECT COUNT(*) AS c FROM wallets',
          ).getSingle();
          if (countResult.read<int>('c') == 0) {
            await into(wallets).insert(
              WalletsCompanion.insert(
                type: const Value('Digital'),
                name: 'Digital (Bank)',
                balance: const Value(0.0),
              ),
            );
            await into(wallets).insert(
              WalletsCompanion.insert(
                type: const Value('Tunai'),
                name: 'Tunai (Laci)',
                balance: const Value(0.0),
              ),
            );
          }
        } catch (_) {}
      }
    },
  );

  /// Resets the application data.
  /// This deletes all transactions, receivables, adjustments, and expenses.
  /// It keeps the User login and Wallets, but resets all wallet balances to 0.
  Future<void> resetAndSeedDatabase() async {
    await transaction(() async {
      // 1. Clear transaction-related tables
      final tablesToClear = [
        transactions,
        expenses,
        receivableLogs,
        receivables,
        adjustments,
        priceConfigs,
        services,
        appSettings, // We'll re-seed settings and services
      ];

      for (final table in tablesToClear) {
        await delete(table as TableInfo).go();
      }

      // 2. Reset Wallet balances to 0 (Keep the wallets themselves)
      await (update(
        wallets,
      )).write(const WalletsCompanion(balance: Value(0.0)));

      // 3. Reset auto-increment counters for cleared tables
      for (final table in tablesToClear) {
        try {
          await customStatement('DELETE FROM sqlite_sequence WHERE name = ?;', [
            Variable.withString((table as TableInfo).actualTableName),
          ]);
        } catch (_) {}
      }

      // 4. Re-seed default settings and services
      await _seedSettingsAndServicesData();
    });
  }

  Future<void> _seedSettingsAndServicesData() async {
    // ── Default Settings ──
    await into(
      appSettings,
    ).insert(AppSettingsCompanion.insert(key: 'shop_name', value: 'KlikAgen'));
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: 'shop_address',
        value: 'Jl. Raya No. 123',
      ),
    );
    await into(appSettings).insert(
      AppSettingsCompanion.insert(key: 'shop_phone', value: '081234567890'),
    );
    await into(
      appSettings,
    ).insert(AppSettingsCompanion.insert(key: 'theme_mode', value: 'dark'));
    await into(
      appSettings,
    ).insert(AppSettingsCompanion.insert(key: 'app_pin', value: '123456'));

    // ── Default Services ──
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'Transfer Sesama BRI',
        adminBank: const Value(0),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'Transfer Antar Bank',
        adminBank: const Value(6500),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'Topup DANA/OVO/GoPay',
        adminBank: const Value(1000),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(name: 'Tarik Tunai', adminBank: const Value(0)),
    );

    // ── Default Price Configs ──
    // ...Transfer
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Transfer',
        minNominal: 0,
        maxNominal: 500000,
        adminUser: 5000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Transfer',
        minNominal: 500001,
        maxNominal: 1000000,
        adminUser: 10000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Transfer',
        minNominal: 1000001,
        maxNominal: 999999999,
        adminUser: 15000,
      ),
    );

    // ...Tarik Tunai
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Tarik Tunai',
        minNominal: 0,
        maxNominal: 500000,
        adminUser: 5000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Tarik Tunai',
        minNominal: 500001,
        maxNominal: 1000000,
        adminUser: 10000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Tarik Tunai',
        minNominal: 1000001,
        maxNominal: 999999999,
        adminUser: 15000,
      ),
    );
  }

  // ═══════════════════════════════════════
  //  SEEDING DATA AWAL
  // ═══════════════════════════════════════

  Future<void> _seedDefaultData() async {
    // ── Default Settings ──
    await into(
      appSettings,
    ).insert(AppSettingsCompanion.insert(key: 'shop_name', value: 'KlikAgen'));
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: 'shop_address',
        value: 'Jl. Raya No. 123',
      ),
    );
    await into(appSettings).insert(
      AppSettingsCompanion.insert(key: 'shop_phone', value: '081234567890'),
    );
    await into(
      appSettings,
    ).insert(AppSettingsCompanion.insert(key: 'theme_mode', value: 'dark'));
    await into(
      appSettings,
    ).insert(AppSettingsCompanion.insert(key: 'app_pin', value: '123456'));

    // ── Default User ──
    await into(users).insert(
      UsersCompanion.insert(
        username: 'admin',
        password: 'admin',
        role: const Value('Admin'),
      ),
    );

    // ── Default Wallets ──
    await into(wallets).insert(
      WalletsCompanion.insert(
        type: const Value('Digital'),
        name: 'Digital (Bank)',
        balance: const Value(5250000.0),
      ),
    );
    await into(wallets).insert(
      WalletsCompanion.insert(
        type: const Value('Tunai'),
        name: 'Tunai (Laci)',
        balance: const Value(3175000.0),
      ),
    );

    // ── Default Services ──
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'Transfer Sesama BRI',
        adminBank: const Value(0),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'Transfer Antar Bank',
        adminBank: const Value(6500),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'TopUp GoPay',
        adminBank: const Value(1000),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(name: 'TopUp OVO', adminBank: const Value(1000)),
    );
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'TopUp DANA',
        adminBank: const Value(1500),
      ),
    );
    await into(services).insert(
      ServicesCompanion.insert(
        name: 'BPJS Kesehatan',
        adminBank: const Value(2500),
      ),
    );

    // ── Default Price Configs (Transfer) ──
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Transfer',
        minNominal: 0,
        maxNominal: 500000,
        adminUser: 3000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Transfer',
        minNominal: 500001,
        maxNominal: 2000000,
        adminUser: 5000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Transfer',
        minNominal: 2000001,
        maxNominal: 10000000,
        adminUser: 10000,
      ),
    );

    // ── Default Price Configs (Tarik Tunai) ──
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Tarik Tunai',
        minNominal: 0,
        maxNominal: 500000,
        adminUser: 3000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Tarik Tunai',
        minNominal: 500001,
        maxNominal: 2000000,
        adminUser: 5000,
      ),
    );
    await into(priceConfigs).insert(
      PriceConfigsCompanion.insert(
        type: 'Tarik Tunai',
        minNominal: 2000001,
        maxNominal: 10000000,
        adminUser: 10000,
      ),
    );
  }

  // ═══════════════════════════════════════
  //  WALLET QUERIES
  // ═══════════════════════════════════════

  Future<List<Wallet>> getAllWallets() => select(wallets).get();

  Stream<List<Wallet>> watchAllWallets() => select(wallets).watch();

  Future<int> insertWallet(WalletsCompanion entry) =>
      into(wallets).insert(entry);

  Future<bool> updateWallet(Wallet entry) => update(wallets).replace(entry);

  Future<int> deleteWallet(int id) =>
      (delete(wallets)..where((w) => w.id.equals(id))).go();

  Future<double> getWalletBalance(int id) async {
    final wallet = await (select(
      wallets,
    )..where((w) => w.id.equals(id))).getSingleOrNull();
    return wallet?.balance ?? 0.0;
  }

  Future<void> updateWalletBalanceDelta(int id, double delta) async {
    await customStatement(
      'UPDATE wallets SET balance = balance + ? WHERE id = ?',
      [delta, id],
    );
  }

  Future<void> setWalletBalance(int id, double balance) async {
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      WalletsCompanion(balance: Value(balance)),
    );
  }

  // ═══════════════════════════════════════
  //  SERVICE QUERIES
  // ═══════════════════════════════════════

  Future<List<Service>> getAllServices() => select(services).get();

  Future<int> insertService(ServicesCompanion entry) =>
      into(services).insert(entry);

  Future<bool> updateService(Service entry) => update(services).replace(entry);

  Future<int> deleteService(int id) =>
      (delete(services)..where((s) => s.id.equals(id))).go();

  // ═══════════════════════════════════════
  //  PRICE CONFIG QUERIES
  // ═══════════════════════════════════════

  Future<List<PriceConfig>> getAllPriceConfigs({String? type}) {
    final query = select(priceConfigs);
    if (type != null) {
      query.where((p) => p.type.equals(type));
    }
    query.orderBy([
      (p) => OrderingTerm.asc(p.type),
      (p) => OrderingTerm.asc(p.minNominal),
    ]);
    return query.get();
  }

  Future<double> getAdminUserForAmount(double amount, String type) async {
    final query = select(priceConfigs)
      ..where(
        (p) =>
            p.type.equals(type) &
            p.minNominal.isSmallerOrEqualValue(amount) &
            p.maxNominal.isBiggerOrEqualValue(amount),
      );
    final result = await query.getSingleOrNull();
    return result?.adminUser ?? 0.0;
  }

  Future<int> insertPriceConfig(PriceConfigsCompanion entry) =>
      into(priceConfigs).insert(entry);

  Future<bool> updatePriceConfig(PriceConfig entry) =>
      update(priceConfigs).replace(entry);

  Future<int> deletePriceConfig(int id) =>
      (delete(priceConfigs)..where((p) => p.id.equals(id))).go();

  // ═══════════════════════════════════════
  //  TRANSACTION QUERIES
  // ═══════════════════════════════════════

  Future<int> insertTxn(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<List<Transaction>> getAllTransactions({int? limit}) {
    final query = select(transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<Transaction?> getTransactionById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteTxn(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<List<Transaction>> getTransactionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Stream<List<Transaction>> watchTransactionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(transactions)
          ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<double> getTodayProfit() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final result = await customSelect(
      'SELECT COALESCE(SUM(profit), 0) AS total FROM transactions WHERE created_at >= ? AND created_at < ?',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
    ).getSingle();
    return result.read<double>('total');
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.createdAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<double> getProfitByDateRange(DateTime start, DateTime end) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(profit), 0) AS total FROM transactions WHERE created_at >= ? AND created_at < ?',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
    ).getSingle();
    return result.read<double>('total');
  }

  Future<int> getTransactionCountByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS total FROM transactions WHERE created_at >= ? AND created_at < ?',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
    ).getSingle();
    return result.read<int>('total');
  }

  // ═══════════════════════════════════════
  //  EXPENSE QUERIES
  // ═══════════════════════════════════════

  Future<int> insertExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<List<Expense>> getAllExpenses({int? limit}) {
    final query = select(expenses)
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  Future<double> getTodayExpenses() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE created_at >= ? AND created_at < ?',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
    ).getSingle();
    return result.read<double>('total');
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) {
    return (select(expenses)
          ..where((e) => e.createdAt.isBetweenValues(start, end))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();
  }

  Future<double> getExpenseTotalByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE created_at >= ? AND created_at < ?',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
    ).getSingle();
    return result.read<double>('total');
  }

  // ═══════════════════════════════════════
  //  RECEIVABLE QUERIES
  // ═══════════════════════════════════════

  Future<int> insertReceivable(ReceivablesCompanion entry) =>
      into(receivables).insert(entry);

  Future<List<Receivable>> getAllReceivables({String? status}) {
    final query = select(receivables);
    if (status != null) {
      query.where((r) => r.status.equals(status));
    }
    return query.get();
  }

  Future<double> getTotalReceivables() async {
    final result = await customSelect(
      "SELECT COALESCE(SUM(total_debt), 0) AS total FROM receivables WHERE status = 'Belum Lunas'",
    ).getSingle();
    return result.read<double>('total');
  }

  Future<void> updateReceivableStatus(int id, String status) async {
    await (update(receivables)..where((r) => r.id.equals(id))).write(
      ReceivablesCompanion(status: Value(status)),
    );
  }

  Future<void> reduceReceivableDebt(int id, double amount) async {
    await transaction(() async {
      await customStatement(
        'UPDATE receivables SET total_debt = total_debt - ? WHERE id = ?',
        [amount, id],
      );
      // Check if cleared
      final rec = await (select(
        receivables,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (rec != null && rec.totalDebt <= 0) {
        await updateReceivableStatus(id, 'Lunas');
      }
    });
  }

  // ═══════════════════════════════════════
  //  RECEIVABLE LOG QUERIES
  // ═══════════════════════════════════════

  Future<int> insertReceivableLog(ReceivableLogsCompanion entry) =>
      into(receivableLogs).insert(entry);

  Future<List<ReceivableLog>> getReceivableLogs(int receivableId) {
    return (select(receivableLogs)
          ..where((l) => l.receivableId.equals(receivableId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  // ═══════════════════════════════════════
  //  ADJUSTMENT QUERIES
  // ═══════════════════════════════════════

  Future<int> insertAdjustment(AdjustmentsCompanion entry) async {
    late int id;
    await transaction(() async {
      id = await into(adjustments).insert(entry);

      final walletId = entry.walletId.value;
      final currentBalance = await getWalletBalance(walletId);
      final amt = entry.amount.value;
      final type = entry.type.value;

      double newBalance = currentBalance;
      if (type == 'Penambahan') {
        newBalance += amt;
      } else if (type == 'Tarik Prive' || type == 'Koreksi Minus') {
        newBalance -= amt;
      } else if (type == 'Pindah Saldo') {
        final fee = entry.fee.value;
        newBalance -= (amt + fee); // Deduct amount + fee from source
        final targetId = entry.targetWalletId.value;
        if (targetId != null) {
          final targetBal = await getWalletBalance(targetId);
          await setWalletBalance(
            targetId,
            targetBal + amt,
          ); // Target gets the full amount
        }
      }
      await setWalletBalance(walletId, newBalance);
    });
    return id;
  }

  Future<List<Adjustment>> getAllAdjustments() {
    return (select(
      adjustments,
    )..orderBy([(a) => OrderingTerm.desc(a.createdAt)])).get();
  }

  // ═══════════════════════════════════════
  //  APP SETTINGS QUERIES
  // ═══════════════════════════════════════

  Future<String?> getSetting(String key) async {
    final result = await (select(
      appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> saveSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (var r in rows) r.key: r.value};
  }

  // ═══════════════════════════════════════
  //  USER QUERIES
  // ═══════════════════════════════════════

  Future<User?> authenticateUser(String username, String password) async {
    return (select(users)..where(
          (u) => u.username.equals(username) & u.password.equals(password),
        ))
        .getSingleOrNull();
  }

  Future<List<User>> getAllUsers() {
    return (select(users)..orderBy([(u) => OrderingTerm.asc(u.id)])).get();
  }

  Future<int> insertUser(UsersCompanion entry) => into(users).insert(entry);

  Future<bool> updateUser(User entry) => update(users).replace(entry);

  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  // ═══════════════════════════════════════
  //  BACKWARD COMPATIBILITY ALIASES
  //  (bridges old DatabaseHelper method names)
  // ═══════════════════════════════════════

  Future<List<Service>> getServices() => getAllServices();
  Future<List<Wallet>> getWallets() => getAllWallets();
  Future<List<User>> getUsers() => getAllUsers();
  Future<List<PriceConfig>> getPriceConfigs({String? type}) =>
      getAllPriceConfigs(type: type);
  Future<List<Transaction>> getTransactions({int? limit}) =>
      getAllTransactions(limit: limit);
  Future<List<Expense>> getExpenses({int? limit}) =>
      getAllExpenses(limit: limit);
  Future<List<Receivable>> getReceivables({String? status}) =>
      getAllReceivables(status: status);
  Future<List<Adjustment>> getAdjustments() => getAllAdjustments();

  /// Get today's transactions
  Future<List<Transaction>> getTransactionsToday() =>
      getTransactionsForDate(DateTime.now());

  /// Alias: old screens use updateWalletBalance(id, delta) = same as updateWalletBalanceDelta
  Future<void> updateWalletBalance(int id, double delta) =>
      updateWalletBalanceDelta(id, delta);

  /// Alias: old screens call insertTransaction with old Transaction model
  Future<int> insertTransaction(Transaction txn) {
    return insertTxn(
      TransactionsCompanion.insert(
        type: txn.type,
        amount: txn.amount,
        adminBank: Value(txn.adminBank),
        adminUser: Value(txn.adminUser),
        profit: Value(txn.profit),
        isPiutang: Value(txn.isPiutang),
        customerName: Value(txn.customerName),
        walletId: Value(txn.walletId),
        createdAt: txn.createdAt,
      ),
    );
  }

  /// Alias: old screens call deleteTransaction(id)
  Future<int> deleteTransaction(int id) => deleteTxn(id);

  /// Old screen-compatible insertExpense using Expense data class
  Future<int> insertExpenseFromModel(Expense e) {
    return insertExpense(
      ExpensesCompanion.insert(
        category: e.category,
        amount: e.amount,
        description: e.description,
        walletId: Value(e.walletId),
        createdAt: e.createdAt,
      ),
    );
  }

  /// Old screen-compatible insertAdjustment using Adjustment data class
  Future<int> insertAdjustmentFromModel(Adjustment a) {
    return insertAdjustment(
      AdjustmentsCompanion.insert(
        type: a.type,
        walletId: Value(a.walletId),
        targetWalletId: Value(a.targetWalletId),
        amount: a.amount,
        description: Value(a.description),
        createdAt: a.createdAt,
      ),
    );
  }

  /// Old screen-compatible insertReceivableLog using ReceivableLog data class
  Future<int> insertReceivableLogFromModel(ReceivableLog l) {
    return insertReceivableLog(
      ReceivableLogsCompanion.insert(
        receivableId: l.receivableId,
        amountPaid: l.amountPaid,
        walletId: Value(l.walletId),
        createdAt: l.createdAt,
      ),
    );
  }
}

// ═══════════════════════════════════════
//  DATABASE CONNECTION
// ═══════════════════════════════════════

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsPath();
    final file = File(p.join(dbFolder, 'klikagen_drift.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Helper to get documents path cross-platform
Future<String> getApplicationDocumentsPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}
