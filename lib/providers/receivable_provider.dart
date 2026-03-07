import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';
import 'dashboard_provider.dart';

class ReceivableState {
  final List<Receivable> receivables;
  final bool isLoading;

  ReceivableState({required this.receivables, this.isLoading = false});
}

class ReceivableNotifier extends StateNotifier<ReceivableState> {
  final AppDatabase db;
  final Ref ref;

  ReceivableNotifier(this.db, this.ref)
    : super(ReceivableState(receivables: []));

  Future<void> loadReceivables({String? status}) async {
    state = ReceivableState(receivables: state.receivables, isLoading: true);
    final list = await db.getAllReceivables(status: status);
    state = ReceivableState(receivables: list, isLoading: false);
  }

  Future<void> insertReceivable(
    String customerName,
    double totalDebt,
    String status,
  ) async {
    await db.insertReceivable(
      ReceivablesCompanion.insert(
        customerName: customerName,
        totalDebt: totalDebt,
        status: status,
      ),
    );
    await loadReceivables();
  }

  Future<void> payReceivable(
    Receivable receivable,
    double amount,
    int walletId,
  ) async {
    await db.insertReceivableLog(
      ReceivableLogsCompanion.insert(
        receivableId: receivable.id,
        amountPaid: amount,
        walletId: Value(walletId),
        createdAt: DateTime.now(),
      ),
    );
    await db.reduceReceivableDebt(receivable.id, amount);
    await db.updateWalletBalanceDelta(walletId, amount);

    await loadReceivables();
    ref.read(dashboardProvider.notifier).loadDashboardData();
  }

  Future<List<ReceivableLog>> getLogs(int receivableId) async {
    return await db.getReceivableLogs(receivableId);
  }
}

final receivableProvider =
    StateNotifierProvider<ReceivableNotifier, ReceivableState>((ref) {
      return ReceivableNotifier(ref.watch(databaseProvider), ref);
    });
