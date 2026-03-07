import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/app_database.dart';
import 'theme/app_theme.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  // Initialize Drift database (auto-loads sqlite3_flutter_libs)
  final db = AppDatabase.instance;

  // Load initial theme from DB
  final dbTheme = await db.getSetting('theme_mode');
  final themeNotifier = ThemeNotifier();
  if (dbTheme != null) {
    themeNotifier.setTheme(dbTheme);
  }

  globalThemeNotifier = themeNotifier;
  runApp(ProviderScope(child: KlikAgenApp(themeNotifier: themeNotifier)));
}

class KlikAgenApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const KlikAgenApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'KlikAgen - BRILink Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.themeMode,
          home: const LoginPage(),
        );
      },
    );
  }
}

/// Global themeNotifier — accessible from settings to toggle theme
late ThemeNotifier globalThemeNotifier;
