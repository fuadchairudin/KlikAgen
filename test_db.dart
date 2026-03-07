import 'dart:io';
import 'package:klik_agen/data/app_database.dart';

void main() async {
  final db = AppDatabase.instance;

  try {
    print('Raw wallets rows:');
    final rows = await db.customSelect('SELECT * FROM wallets').get();
    for (var row in rows) {
      print(row.data);
    }
  } catch (e, st) {
    print('Error: $e\n$st');
  }

  exit(0);
}
