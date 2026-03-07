import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';
import 'dashboard_provider.dart';

class AdjustmentState {
  final List<Adjustment> adjustments;
  final bool isLoading;

  AdjustmentState({required this.adjustments, this.isLoading = false});
}

class AdjustmentNotifier extends StateNotifier<AdjustmentState> {
  final AppDatabase db;
  final Ref ref;

  AdjustmentNotifier(this.db, this.ref)
    : super(AdjustmentState(adjustments: []));

  Future<void> loadAdjustments() async {
    state = AdjustmentState(adjustments: state.adjustments, isLoading: true);
    final list = await db.getAllAdjustments();
    state = AdjustmentState(adjustments: list, isLoading: false);
  }

  Future<void> addAdjustment(
    String type,
    int walletId,
    double amount,
    String? description, {
    int? targetWalletId,
    double fee = 0,
  }) async {
    await db.insertAdjustment(
      AdjustmentsCompanion.insert(
        type: type,
        walletId: Value(walletId),
        targetWalletId: Value(targetWalletId),
        amount: amount,
        fee: Value(fee),
        description: Value(description),
        createdAt: DateTime.now(),
      ),
    );
    await loadAdjustments();
    ref.read(dashboardProvider.notifier).loadDashboardData();
  }
}

final adjustmentProvider =
    StateNotifierProvider<AdjustmentNotifier, AdjustmentState>((ref) {
      return AdjustmentNotifier(ref.watch(databaseProvider), ref);
    });
