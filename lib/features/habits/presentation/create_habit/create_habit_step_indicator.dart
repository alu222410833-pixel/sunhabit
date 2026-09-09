import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class CreateHabitStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const CreateHabitStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final active = index <= currentStep;
        return Row(
          children: [
            if (index > 0)
              Container(
                width: 24,
                height: 2,
                color: active ? AppColors.neonGreen : AppColors.borderDark,
              ),
            if (index > 0) const SizedBox(width: 4),
            Container(
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
                '${index + 1}',
                style: TextStyle(
                  color: active ? const Color(0xFF152000) : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
