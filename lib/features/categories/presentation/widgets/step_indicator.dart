import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

/// Indicador visual de pasos para el diálogo de creación de categoría.
class StepIndicator extends StatelessWidget {
  final int currentStep;

  const StepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepDot(active: currentStep == 0, label: '1'),
        const SizedBox(width: 8),
        Container(width: 24, height: 2, color: AppColors.borderDark),
        const SizedBox(width: 8),
        _StepDot(active: currentStep == 1, label: '2'),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;

  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.neonGreen : AppColors.surfaceHighest,
        border: Border.all(
          color: active ? AppColors.neonGreen : AppColors.borderDark,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF152000) : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
