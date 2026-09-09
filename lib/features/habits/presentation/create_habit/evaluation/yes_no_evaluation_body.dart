import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class YesNoEvaluationBody extends StatelessWidget {
  const YesNoEvaluationBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Este hábito se marca como completado con un simple Sí o No.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}
