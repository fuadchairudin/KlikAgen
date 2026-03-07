import 'package:flutter/services.dart';

/// Formatter yang otomatis menambahkan separator titik ribuan
/// saat user mengetik angka. Contoh: 1000000 → 1.000.000
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua non-digit
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format dengan separator titik
    final formatted = _addSeparator(digitsOnly);

    // Hitung posisi cursor baru
    // Jumlah digit sebelum cursor di text lama
    final oldCursorPos = newValue.selection.baseOffset;
    final oldTextBeforeCursor = newValue.text.substring(
      0,
      oldCursorPos.clamp(0, newValue.text.length),
    );
    final digitsBeforeCursor = oldTextBeforeCursor
        .replaceAll(RegExp(r'[^\d]'), '')
        .length;

    // Hitung posisi cursor di string yang sudah diformat
    int newCursorPos = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (digitCount == digitsBeforeCursor) break;
      if (formatted[i] != '.') {
        digitCount++;
      }
      newCursorPos = i + 1;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formatted.length),
      ),
    );
  }

  String _addSeparator(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      buffer.write(digits[i]);
      final remaining = length - 1 - i;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

/// Helper untuk parse string yang sudah diformat ke double
/// Contoh: "1.000.000" → 1000000.0
double parseFormattedNumber(String text) {
  return double.tryParse(text.replaceAll('.', '')) ?? 0;
}
