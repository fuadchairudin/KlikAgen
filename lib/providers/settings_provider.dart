import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';

class SettingsState {
  final List<Service> services;
  final List<PriceConfig> priceConfigs;
  final List<User> users;
  final List<Wallet> wallets;
  final Map<String, String> settings;
  final bool isLoading;

  SettingsState({
    this.services = const [],
    this.priceConfigs = const [],
    this.users = const [],
    this.wallets = const [],
    this.settings = const {},
    this.isLoading = false,
  });
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final AppDatabase db;
  SettingsNotifier(this.db) : super(SettingsState());

  Future<void> loadData() async {
    state = SettingsState(
      services: state.services,
      priceConfigs: state.priceConfigs,
      users: state.users,
      wallets: state.wallets,
      settings: state.settings,
      isLoading: true,
    );
    final services = await db.getAllServices();
    final configs = await db.getAllPriceConfigs();
    final users = await db.getAllUsers();
    final wallets = await db.getWallets();
    final settingsMap = await db.getAllSettings();
    state = SettingsState(
      services: services,
      priceConfigs: configs,
      users: users,
      wallets: wallets,
      settings: settingsMap,
      isLoading: false,
    );
  }

  // Helper method that can be expanded if needed
  Future<void> refresh() => loadData();
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(ref.watch(databaseProvider));
  },
);
