import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/number_input.dart';

class RepeatFrequencyPicker extends StatelessWidget {
  final int days;
  final ValueChanged<int> onDaysChanged;

  const RepeatFrequencyPicker({
    super.key,
    required this.days,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Repetir cada', style: textTheme.bodyMedium),
            const SizedBox(width: 10),
            NumberInput(
              value: days,
              onChanged: onDaysChanged,
            ),
            const SizedBox(width: 10),
            Text('días', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
