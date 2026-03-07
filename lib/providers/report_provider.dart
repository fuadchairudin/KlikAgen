import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';

// ═══════════════════════════════════════
//  REPORT STATE
// ═══════════════════════════════════════

class ReportState {
  final DateTime startDate;
  final DateTime endDate;
  final List<Transaction> transactions;
  final List<Expense> expenses;
  final double totalProfit;
  final double totalExpenses;
  final int transactionCount;
  final bool isLoading;

  const ReportState({
    required this.startDate,
    required this.endDate,
    this.transactions = const [],
    this.expenses = const [],
    this.totalProfit = 0,
    this.totalExpenses = 0,
    this.transactionCount = 0,
    this.isLoading = false,
  });

  ReportState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<Transaction>? transactions,
    List<Expense>? expenses,
    double? totalProfit,
    double? totalExpenses,
    int? transactionCount,
    bool? isLoading,
  }) {
    return ReportState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactions: transactions ?? this.transactions,
      expenses: expenses ?? this.expenses,
      totalProfit: totalProfit ?? this.totalProfit,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      transactionCount: transactionCount ?? this.transactionCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get netProfit => totalProfit - totalExpenses;
}

// ═══════════════════════════════════════
//  REPORT PROVIDER
// ═══════════════════════════════════════

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((
  ref,
) {
  final now = DateTime.now();
  return ReportNotifier(
    ref.read(databaseProvider),
    DateTime(now.year, now.month, 1),
    DateTime(now.year, now.month + 1, 1),
  );
});

class ReportNotifier extends StateNotifier<ReportState> {
  final AppDatabase _db;

  ReportNotifier(this._db, DateTime start, DateTime end)
    : super(ReportState(startDate: start, endDate: end)) {
    loadReport();
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true);
    final txns = await _db.getTransactionsByDateRange(
      state.startDate,
      state.endDate,
    );
    final expenses = await _db.getExpensesByDateRange(
      state.startDate,
      state.endDate,
    );
    final profit = await _db.getProfitByDateRange(
      state.startDate,
      state.endDate,
    );
    final expTotal = await _db.getExpenseTotalByDateRange(
      state.startDate,
      state.endDate,
    );
    final count = await _db.getTransactionCountByDateRange(
      state.startDate,
      state.endDate,
    );

    state = state.copyWith(
      transactions: txns,
      expenses: expenses,
      totalProfit: profit,
      totalExpenses: expTotal,
      transactionCount: count,
      isLoading: false,
    );
  }
}
