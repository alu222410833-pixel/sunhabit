import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/evaluation/evaluation_segmented_control.dart';

class AmountEvaluationBody extends StatelessWidget {
  final String condition;
  final List<String> conditions;
  final TextEditingController targetController;
  final int target;
  final String unit;
  final List<String> units;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<String> onUnitChanged;

  const AmountEvaluationBody({
    super.key,
    required this.condition,
    required this.conditions,
    required this.targetController,
    required this.target,
    required this.unit,
    required this.units,
    required this.onConditionChanged,
    required this.onTargetChanged,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Condición', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        EvaluationSegmentedControl(
          values: conditions,
          selected: condition,
          onSelected: onConditionChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value) ?? target;
                  onTargetChanged(parsed);
                },
                decoration: const InputDecoration(
                  labelText: 'Objetivo',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceHighest,
                    style: Theme.of(context).textTheme.bodyLarge,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.textSecondary),
                    items: units.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) onUnitChanged(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
