import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class ProductRadioSelector extends StatelessWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const ProductRadioSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selectedValue,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      child: Wrap(
        spacing: 16,
        children: options.map((option) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: option,
                activeColor: AppColors.pri,
              ),
              Text(
                option,
                style: GoogleFonts.mukta(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
