import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';

class DashboardState {
  final List<Wallet> digitalWallets;
  final Wallet? tunaiWallet;
  final double totalAsset;
  final double todayProfit;
  final double totalReceivables;
  final double monthlyExpenses;
  final int todayTxnCount;
  final List<Transaction> recentTransactions;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.digitalWallets = const [],
    this.tunaiWallet,
    this.totalAsset = 0,
    this.todayProfit = 0,
    this.totalReceivables = 0,
    this.monthlyExpenses = 0,
    this.todayTxnCount = 0,
    this.recentTransactions = const [],
    this.isLoading = true,
    this.errorMessage,
  });
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final AppDatabase db;
  final Ref ref;

  DashboardNotifier(this.db, this.ref) : super(DashboardState());

  Future<void> loadDashboardData() async {
    try {
      state = DashboardState(isLoading: true, errorMessage: 'wallets');

      final wallets = await db.getAllWallets();
      List<Wallet> digitals = [];
      Wallet? tunai;
      double totalAsset = 0;
      for (var w in wallets) {
        totalAsset += w.balance;
        if (w.type == 'Tunai') tunai = w;
        if (w.type == 'Digital') digitals.add(w);
      }

      state = DashboardState(isLoading: true, errorMessage: 'todayProfit');
      final todayProfit = await db.getTodayProfit();

      state = DashboardState(isLoading: true, errorMessage: 'totalReceivables');
      final totalReceivables = await db.getTotalReceivables();

      state = DashboardState(isLoading: true, errorMessage: 'monthlyExpenses');
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      final monthlyExpenses = await db.getExpenseTotalByDateRange(
        monthStart,
        monthEnd,
      );

      state = DashboardState(isLoading: true, errorMessage: 'todayTxnCount');
      final todayTxns = await db.getTransactionsForDate(now);
      final todayTxnCount = todayTxns.length;

      state = DashboardState(isLoading: true, errorMessage: 'recentTxns');
      final recentTxns = await db.getAllTransactions(limit: 5);

      state = DashboardState(
        digitalWallets: digitals,
        tunaiWallet: tunai,
        totalAsset: totalAsset,
        todayProfit: todayProfit,
        totalReceivables: totalReceivables,
        monthlyExpenses: monthlyExpenses,
        todayTxnCount: todayTxnCount,
        recentTransactions: recentTxns,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e, st) {
      print('DEBUG Dashboard Error: $e\n$st');
      state = DashboardState(
        isLoading: false,
        errorMessage: '[FAIL AT: ${state.errorMessage}] ${e.toString()}',
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final db = ref.watch(databaseProvider);
      return DashboardNotifier(db, ref);
    });
