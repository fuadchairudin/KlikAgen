import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';
import 'dashboard_provider.dart';
import 'report_provider.dart';

class ExpenseState {
  final List<Expense> expenses;
  final bool isLoading;

  ExpenseState({required this.expenses, this.isLoading = false});
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final AppDatabase db;
  final Ref ref;

  ExpenseNotifier(this.db, this.ref) : super(ExpenseState(expenses: []));

  Future<void> loadExpenses() async {
    state = ExpenseState(expenses: state.expenses, isLoading: true);
    final list = await db.getAllExpenses();
    state = ExpenseState(expenses: list, isLoading: false);
  }

  Future<void> addExpense(
    String category,
    double amount,
    String description,
    int walletId,
    DateTime date,
  ) async {
    await db.insertExpense(
      ExpensesCompanion.insert(
        category: category,
        amount: amount,
        description: description,
        walletId: Value(walletId),
        createdAt: date,
      ),
    );
    await db.updateWalletBalanceDelta(walletId, -amount);

    await loadExpenses();
    _refreshDependentProviders();
  }

  Future<void> deleteExpense(Expense expense) async {
    await db.deleteExpense(expense.id);
    await db.updateWalletBalanceDelta(expense.walletId, expense.amount);

    await loadExpenses();
    _refreshDependentProviders();
  }

  void _refreshDependentProviders() {
    ref.read(dashboardProvider.notifier).loadDashboardData();
    ref.read(reportProvider.notifier).loadReport();
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((
  ref,
) {
  return ExpenseNotifier(ref.watch(databaseProvider), ref);
});
