import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';
import 'app_date_provider.dart';
import 'dashboard_provider.dart';
import 'receivable_provider.dart';
import 'report_provider.dart';

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  TransactionState({
    required this.transactions,
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final AppDatabase db;
  final Ref ref;

  TransactionNotifier(this.db, this.ref)
    : super(TransactionState(transactions: []));

  Future<void> loadTransactions(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final txns = await db.getTransactionsForDate(date);
      state = state.copyWith(transactions: txns, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  double calculateProfit(double adminUser, double adminBank) {
    return adminUser - adminBank;
  }

  Future<bool> validateBalanceForTransfer(
    int walletId,
    double nominal,
    double adminBank, {
    int? editingId,
  }) async {
    double digitalBalance = await db.getWalletBalance(walletId);
    if (editingId != null) {
      final oldTxn = await db.getTransactionById(editingId);
      if (oldTxn != null &&
          oldTxn.type == 'Transfer' &&
          oldTxn.walletId == walletId) {
        digitalBalance += (oldTxn.amount + oldTxn.adminBank);
      }
    }
    return digitalBalance >= (nominal + adminBank);
  }

  Future<bool> validateBalanceForTarikTunai(
    double nominal,
    double adminUser, {
    int? editingId,
  }) async {
    double tunaiBalance = await db.getWalletBalance(2); // 2 is Tunai
    if (editingId != null) {
      final oldTxn = await db.getTransactionById(editingId);
      if (oldTxn != null && oldTxn.type == 'Tarik Tunai') {
        tunaiBalance += (oldTxn.amount - oldTxn.adminUser);
      }
    }
    return tunaiBalance >= (nominal - adminUser);
  }

  Future<void> submitTransaction({
    required int? editingId,
    required String type,
    required int walletId,
    required double nominal,
    required double adminBank,
    required double adminUser,
    required double profit,
    required bool isPiutang,
    required String customerName,
    required DateTime date,
  }) async {
    int? currentReceivableId;

    if (editingId != null) {
      final oldTxn = await db.getTransactionById(editingId);
      if (oldTxn != null) {
        currentReceivableId = oldTxn.receivableId;
        await deleteTransaction(oldTxn, isEditing: true);
      }
    }

    if (isPiutang) {
      if (currentReceivableId != null) {
        // Update existing receivable instead of creating new
        await db.customStatement(
          'UPDATE receivables SET customer_name = ?, total_debt = ?, status = ? WHERE id = ?',
          [
            customerName,
            nominal + adminUser,
            'Belum Lunas',
            currentReceivableId,
          ],
        );
      } else {
        currentReceivableId = await db.insertReceivable(
          ReceivablesCompanion.insert(
            customerName: customerName,
            totalDebt: nominal + adminUser,
            status: 'Belum Lunas',
          ),
        );
      }
    } else {
      // Jika diedit menjadi BUKAN piutang, hapus piutang lamanya
      if (currentReceivableId != null) {
        await db.transaction(() async {
          await db.customStatement(
            'DELETE FROM receivable_logs WHERE receivable_id = ?',
            [currentReceivableId],
          );
          await db.customStatement('DELETE FROM receivables WHERE id = ?', [
            currentReceivableId,
          ]);
        });
        currentReceivableId = null;
      }
    }

    await db.insertTxn(
      TransactionsCompanion.insert(
        type: type,
        walletId: Value(walletId),
        amount: nominal,
        adminBank: Value(adminBank),
        adminUser: Value(adminUser),
        profit: Value(profit),
        isPiutang: Value(isPiutang ? 1 : 0),
        customerName: Value(isPiutang ? customerName : null),
        receivableId: Value(currentReceivableId),
        createdAt: date,
      ),
    );

    if (type == 'Transfer') {
      await db.updateWalletBalanceDelta(walletId, -(nominal + adminBank));
      if (!isPiutang) {
        await db.updateWalletBalanceDelta(2, nominal + adminUser); // 2 is Tunai
      }
    } else if (type == 'Tarik Tunai') {
      await db.updateWalletBalanceDelta(walletId, nominal);
      await db.updateWalletBalanceDelta(
        2,
        -(nominal - adminUser),
      ); // 2 is Tunai
    }

    await loadTransactions(ref.read(appDateProvider));
    _refreshDependentProviders();
  }

  /// Refresh dashboard, report, and receivable providers so they reflect latest data
  void _refreshDependentProviders() {
    ref.read(dashboardProvider.notifier).loadDashboardData();
    ref.read(reportProvider.notifier).loadReport();
    ref.read(receivableProvider.notifier).loadReceivables();
  }

  Future<void> deleteTransaction(
    Transaction txn, {
    bool isEditing = false,
  }) async {
    if (txn.type == 'Transfer') {
      await db.updateWalletBalanceDelta(
        txn.walletId,
        (txn.amount + txn.adminBank),
      );
      if (txn.isPiutang == 0) {
        await db.updateWalletBalanceDelta(
          2,
          -(txn.amount + txn.adminUser),
        ); // 2 is Tunai
      }
    } else if (txn.type == 'Tarik Tunai') {
      await db.updateWalletBalanceDelta(txn.walletId, -txn.amount);
      await db.updateWalletBalanceDelta(
        2,
        (txn.amount - txn.adminUser),
      ); // 2 is Tunai
    }

    if (txn.receivableId != null && !isEditing) {
      await db.transaction(() async {
        await db.customStatement(
          'DELETE FROM receivable_logs WHERE receivable_id = ?',
          [txn.receivableId],
        );
        await db.customStatement('DELETE FROM receivables WHERE id = ?', [
          txn.receivableId,
        ]);
      });
    }

    await db.deleteTransaction(txn.id);

    if (!isEditing) {
      await loadTransactions(ref.read(appDateProvider));
      _refreshDependentProviders();
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
      final db = ref.watch(databaseProvider);
      return TransactionNotifier(db, ref);
    });
