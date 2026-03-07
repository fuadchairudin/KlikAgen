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
    double adminBank,
  ) async {
    final digitalBalance = await db.getWalletBalance(walletId);
    return digitalBalance >= (nominal + adminBank);
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
    if (editingId != null) {
      final oldTxn = await db.getTransactionById(editingId);
      if (oldTxn != null) {
        await deleteTransaction(oldTxn, isEditing: true);
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

    if (isPiutang) {
      await db.insertReceivable(
        ReceivablesCompanion.insert(
          customerName: customerName,
          totalDebt: nominal + adminUser,
          status: 'Belum Lunas',
        ),
      );
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
