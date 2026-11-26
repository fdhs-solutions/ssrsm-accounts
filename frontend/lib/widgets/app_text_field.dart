import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class AppFieldLabel extends StatelessWidget {
  final String text;
  final double fontSize;

  const AppFieldLabel(this.text, {super.key, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.mukta(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.mut,
      ),
    );
  }
}

InputDecoration appInputDecoration({
  String? hintText,
  String? labelText,
  Widget? suffixIcon,
  EdgeInsetsGeometry contentPadding =
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.card,
    contentPadding: contentPadding,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.pri, width: 2),
    ),
  );
}
