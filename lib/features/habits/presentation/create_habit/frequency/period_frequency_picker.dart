import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/number_input.dart';

class PeriodFrequencyPicker extends StatelessWidget {
  final int timesPerPeriod;
  final String periodType;
  final int repeatInterval;
  final ValueChanged<int> onTimesChanged;
  final ValueChanged<String> onPeriodTypeChanged;
  final ValueChanged<int> onRepeatIntervalChanged;

  const PeriodFrequencyPicker({
    super.key,
    required this.timesPerPeriod,
    required this.periodType,
    required this.repeatInterval,
    required this.onTimesChanged,
    required this.onPeriodTypeChanged,
    required this.onRepeatIntervalChanged,
  });

  static const List<String> _periods = ['semana', 'mes', 'año'];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Veces', style: textTheme.labelSmall),
                  const SizedBox(height: 4),
                  NumberInput(
                    value: timesPerPeriod,
                    onChanged: onTimesChanged,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _LabeledDropdown<String>(
                  label: 'Por',
                  value: periodType,
                  items: _periods
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onPeriodTypeChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Repetir cada', style: textTheme.bodyMedium),
                const SizedBox(width: 10),
                NumberInput(
                  value: repeatInterval,
                  onChanged: onRepeatIntervalChanged,
                ),
                const SizedBox(width: 10),
                Text('días', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              dropdownColor: AppColors.surfaceDark,
              style: textTheme.titleMedium,
              iconEnabledColor: AppColors.textSecondary,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
