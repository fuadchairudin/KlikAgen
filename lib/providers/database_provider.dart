import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_database.dart';

/// Root provider for the AppDatabase instance.
/// This allows us to inject the database anywhere in the provider tree
/// and easily swap it out for a mock database during testing.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
