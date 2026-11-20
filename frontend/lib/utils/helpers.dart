import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

final _inrFormat = NumberFormat('#,##,##0.##', 'en_IN');

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
  final mon = now.subtract(Duration(days: (now.weekday - 1)));
  final sun = mon.add(const Duration(days: 6));
  return DateTimeRange(
    start: DateTime(mon.year, mon.month, mon.day),
    end: DateTime(sun.year, sun.month, sun.day),
  );
}

DateTimeRange thisMonthRange() {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month + 1, 0),
  );
}

DateTimeRange thisYearRange() {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, 1, 1),
    end: DateTime(now.year, 12, 31),
  );
}
