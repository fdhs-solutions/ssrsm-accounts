import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _inrFormat = NumberFormat('#,##,##0.##', 'en_IN');

/// Format raw number string or num into Indian comma style (e.g. 100000 -> "1,00,000")
String formatIndianNumber(String val) {
  if (val.isEmpty) return '';
  final clean = val.replaceAll(',', '').trim();
  if (clean.isEmpty) return '';
  final parts = clean.split('.');
  final integerPart = parts[0];
  if (integerPart.isEmpty) return '';

  String res = '';
  final len = integerPart.length;
  if (len <= 3) {
    res = integerPart;
  } else {
    final lastThree = integerPart.substring(len - 3);
    final rest = integerPart.substring(0, len - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    res = '${buffer.toString()},$lastThree';
  }

  if (parts.length > 1) {
    res = '$res.${parts[1]}';
  }
  return res;
}

/// TextInputFormatter that auto-formats integer/decimal inputs in Indian number style (1,00,000)
class IndianNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final raw = newValue.text.replaceAll(',', '');
    // Allow digits and at most one decimal point
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(raw)) {
      return oldValue;
    }

    final formatted = formatIndianNumber(raw);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String inr(num n) => '\u20B9${_inrFormat.format(n)}';

String inrPlain(num n) => _inrFormat.format(n);

String formatNum(dynamic val) {
  if (val == null) return '';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();
  if (d == 0) return '';
  if (d % 1 == 0) return d.toInt().toString();
  return d.toStringAsFixed(2);
}

String formatNumWithZero(dynamic val) {
  if (val == null) return '0';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();
  if (d % 1 == 0) return d.toInt().toString();
  return d.toStringAsFixed(2);
}

String formatDate(String iso) {
  if (iso.isEmpty) return '';
  // Handles both YYYY-MM-DD and full ISO strings like 2026-11-20T00:00:00.000Z
  final cleanDate = iso.split('T')[0];
  final parts = cleanDate.split('-');
  if (parts.length != 3) return iso;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String todayISO() {
  final now = DateTime.now();
  return DateFormat('yyyy-MM-dd').format(now);
}

String dateLabel(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

String dateISO(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

DateTimeRange thisWeekRange() {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  final start = end.subtract(const Duration(days: 6)); // Past 6 days + today = 7 days
  return DateTimeRange(start: start, end: end);
}

DateTimeRange thisMonthRange() {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  final start = end.subtract(const Duration(days: 29)); // Past 29 days + today = 30 days
  return DateTimeRange(start: start, end: end);
}

DateTimeRange thisYearRange() {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  final start = end.subtract(const Duration(days: 364)); // Past 364 days + today = 365 days
  return DateTimeRange(start: start, end: end);
}
