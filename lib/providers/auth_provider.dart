import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';
import 'database_provider.dart';

/// Provider to store the currently logged-in user.
/// Returns null if no user is authenticated.
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final db = ref.watch(databaseProvider);
  return AuthNotifier(db);
});

class AuthNotifier extends StateNotifier<User?> {
  final AppDatabase db;
  String? error;

  AuthNotifier(this.db) : super(null);

  Future<void> loadLastUser() async {
    // For now, load first user as default or implement logic
    final users = await db.getAllUsers();
    if (users.isNotEmpty) {
      state = users.first; // In real app, load from shared_preferences
    }
  }

  Future<bool> login(String username, String password) async {
    error = null;
    final user = await db.authenticateUser(username, password);
    if (user != null) {
      state = user;
      return true;
    } else {
      error = 'Username atau password salah!';
      return false;
    }
  }

  void logout() {
    state = null;
  }
}
