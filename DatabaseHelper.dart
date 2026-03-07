import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('brilink_pro_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const floatType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Wallets (Digital & Tunai)
    await db.execute(
      'CREATE TABLE wallets (id $idType, name $textType, balance $floatType)',
    );

    // 2. Services (Admin Bank)
    await db.execute(
      'CREATE TABLE services (id $idType, name $textType, admin_bank $floatType)',
    );

    // 3. Price Configs (Admin Pelanggan berdasarkan Range)
    await db.execute(
      'CREATE TABLE price_configs (id $idType, min_nominal $floatType, max_nominal $floatType, admin_user $floatType)',
    );

    // 4. Transactions (Log Utama)
    await db.execute('''CREATE TABLE transactions (
      id $idType, type $textType, amount $floatType, admin_bank $floatType, 
      admin_user $floatType, profit $floatType, is_piutang $intType, 
      customer_name TEXT, created_at $textType
    )''');

    // 5. Expenses (Pengeluaran Operasional)
    await db.execute(
      'CREATE TABLE expenses (id $idType, category $textType, amount $floatType, description $textType, created_at $textType)',
    );

    // 6. Receivables (Buku Piutang)
    await db.execute(
      'CREATE TABLE receivables (id $idType, customer_name $textType, total_debt $floatType, status $textType)',
    );

    // SEEDING DATA AWAL
    await db.insert('wallets', {
      'id': 1,
      'name': 'Digital (Bank)',
      'balance': 0.0,
    });
    await db.insert('wallets', {
      'id': 2,
      'name': 'Tunai (Laci)',
      'balance': 0.0,
    });

    // Default Admin User Range (0 - 1jt -> 5000)
    await db.insert('price_configs', {
      'min_nominal': 0,
      'max_nominal': 1000000,
      'admin_user': 5000,
    });
  }

  // --- LOGIKA KASIR (TRANSAKSI UTAMA) ---

  Future<void> saveTransaction({
    required String type,
    required double amount,
    required double adminBank,
    required double adminUser,
    required bool isPiutang,
    String? customerName,
    bool isAdminDalam = false, // Khusus Tarik Tunai
  }) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    double profit = (type == 'Transfer') ? (adminUser - adminBank) : adminUser;

    await db.transaction((txn) async {
      // 1. Catat di Tabel Transaksi
      await txn.insert('transactions', {
        'type': type,
        'amount': amount,
        'admin_bank': adminBank,
        'admin_user': adminUser,
        'profit': profit,
        'is_piutang': isPiutang ? 1 : 0,
        'customer_name': customerName,
        'created_at': now,
      });

      if (type == 'Transfer') {
        // Update Bank (Kurangi Nominal + Admin Bank)
        await txn.rawUpdate(
          'UPDATE wallets SET balance = balance - ? WHERE id = 1',
          [amount + adminBank],
        );

        if (isPiutang) {
          // Jika Piutang: Masukkan ke Tabel Piutang (Nominal + Admin)
          await txn.insert('receivables', {
            'customer_name': customerName ?? 'Hamba Allah',
            'total_debt': amount + adminUser,
            'status': 'Belum Lunas',
          });
        } else {
          // Jika Tunai: Update Laci (Tambah Nominal + Admin User)
          await txn.rawUpdate(
            'UPDATE wallets SET balance = balance + ? WHERE id = 2',
            [amount + adminUser],
          );
        }
      } else if (type == 'Tarik Tunai') {
        // Update Bank (Tambah Nominal Tarik)
        await txn.rawUpdate(
          'UPDATE wallets SET balance = balance + ? WHERE id = 1',
          [amount],
        );

        if (isPiutang) {
          // Jarang terjadi, tapi jika pelanggan narik uang tapi belum bayar saldo digital ke kita
          await txn.insert('receivables', {
            'customer_name': customerName ?? 'Hamba Allah',
            'total_debt': amount,
            'status': 'Belum Lunas',
          });
        } else {
          // Update Laci (Kurangi uang fisik yang diberikan ke pelanggan)
          double physicalCashOut = isAdminDalam ? (amount - adminUser) : amount;
          await txn.rawUpdate(
            'UPDATE wallets SET balance = balance - ? WHERE id = 2',
            [physicalCashOut],
          );

          // Jika Admin Luar, uang admin masuk laci lagi (Net: amount - adminUser)
        }
      }
    });
  }

  // --- AUTOMATION LOOKUP (UNTUK UI) ---

  // Mencari admin pelanggan otomatis berdasarkan nominal
  Future<double> getAutoAdminUser(double nominal) async {
    final db = await instance.database;
    final res = await db.query(
      'price_configs',
      where: '? BETWEEN min_nominal AND max_nominal',
      whereArgs: [nominal],
    );
    return res.isNotEmpty ? (res.first['admin_user'] as double) : 0.0;
  }

  // --- LAPORAN CEPAT (F5) ---

  Future<Map<String, dynamic>> getDailySummary() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // YYYY-MM-DD

    final res = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_count,
        SUM(profit) as total_profit,
        SUM(CASE WHEN type = 'Transfer' THEN amount ELSE 0 END) as total_transfer,
        SUM(CASE WHEN type = 'Tarik Tunai' THEN amount ELSE 0 END) as total_tarik
      FROM transactions 
      WHERE created_at LIKE '$today%'
    ''');

    return res.first;
  }

  // --- PENYESUAIAN SALDO (F7) ---

  Future<void> adjustBalance(int walletId, double amount, String note) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE wallets SET balance = balance + ? WHERE id = ?',
        [amount, walletId],
      );
      await txn.insert('transactions', {
        'type': 'Adjustment',
        'amount': amount,
        'admin_bank': 0,
        'admin_user': 0,
        'profit': 0,
        'is_piutang': 0,
        'customer_name': note,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // --- MANAJEMEN PENGELUARAN (F8) ---

  Future<void> addExpense(String category, double amount, String desc) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('expenses', {
        'category': category,
        'amount': amount,
        'description': desc,
        'created_at': DateTime.now().toIso8601String(),
      });
      // Pengeluaran biasanya memotong saldo Tunai (Laci)
      await txn.rawUpdate(
        'UPDATE wallets SET balance = balance - ? WHERE id = 2',
        [amount],
      );
    });
  }
}
