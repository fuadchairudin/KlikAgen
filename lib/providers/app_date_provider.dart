import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the operational date of the application.
/// Defaults to today's date but can be overridden by the user.
final appDateProvider = StateNotifierProvider<AppDateNotifier, DateTime>((ref) {
  return AppDateNotifier();
});

class AppDateNotifier extends StateNotifier<DateTime> {
  AppDateNotifier() : super(DateTime.now());

  void setDate(DateTime newDate) {
    state = newDate;
  }

  void resetToToday() {
    state = DateTime.now();
  }

  bool get isToday {
    final now = DateTime.now();
    return state.year == now.year &&
        state.month == now.month &&
        state.day == now.day;
  }
}
