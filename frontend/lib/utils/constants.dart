import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFFF3F5FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF14173A);
  static const Color mut = Color(0xFF69708F);
  static const Color line = Color(0xFFE3E6F2);
  static const Color pri = Color(0xFF4338CA);
  static const Color onPri = Color(0xFFFFFFFF);
  static const Color acc = Color(0xFFD97706);
  static const Color ok = Color(0xFF059669);
  static const Color bad = Color(0xFFDC2626);
  static const Color tint = Color(0xFFEEF0FF);

  static const Color bgDark = Color(0xFF0B1020);
  static const Color cardDark = Color(0xFF151B30);
  static const Color inkDark = Color(0xFFEEF1FA);
  static const Color mutDark = Color(0xFF9AA4C0);
  static const Color lineDark = Color(0xFF273050);
  static const Color priDark = Color(0xFF818CF8);
  static const Color onPriDark = Color(0xFF0B1020);
  static const Color accDark = Color(0xFFFBBF24);
  static const Color okDark = Color(0xFF34D399);
  static const Color badDark = Color(0xFFF87171);
  static const Color tintDark = Color(0xFF1E2647);

  static const Color cashColor = Color(0xFF059669);
  static const Color chequeColor = Color(0xFFD97706);
  static const Color rtgsColor = Color(0xFF4F46E5);
  static const Color autoColor = Color(0xFF06B6D4);
  static const Color creditColor = Color(0xFF8B5CF6);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF06B6D4)],
  );
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4338CA), Color(0xFF4F46E5)],
  );
}

class ApiConfig {
  static String get baseUrl {
    return 'https://ssrsm-accounts-api.fdhs-solution.com/api';
  }
}
