import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class EvaluationSegmentedControl extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  const EvaluationSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final active = value == selected;
        return GestureDetector(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.neonGreen : AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(
                color: active ? AppColors.neonGreen : AppColors.borderDark,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: active ? const Color(0xFF152000) : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
