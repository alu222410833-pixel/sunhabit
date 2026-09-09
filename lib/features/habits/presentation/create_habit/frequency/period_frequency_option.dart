import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/period_frequency_picker.dart';

class PeriodFrequencyOption extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onSelected;
  final int timesPerPeriod;
  final String periodType;
  final int repeatInterval;
  final ValueChanged<int> onTimesChanged;
  final ValueChanged<String> onPeriodTypeChanged;
  final ValueChanged<int> onRepeatIntervalChanged;

  const PeriodFrequencyOption({
    super.key,
    required this.selectedFrequency,
    required this.onSelected,
    required this.timesPerPeriod,
    required this.periodType,
    required this.repeatInterval,
    required this.onTimesChanged,
    required this.onPeriodTypeChanged,
    required this.onRepeatIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    const title = 'Algunas veces por período';
    return FrequencyOption(
      title: title,
      isSelected: selectedFrequency == title,
      onTap: () => onSelected(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configura la periodicidad', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          PeriodFrequencyPicker(
            timesPerPeriod: timesPerPeriod,
            periodType: periodType,
            repeatInterval: repeatInterval,
            onTimesChanged: onTimesChanged,
            onPeriodTypeChanged: onPeriodTypeChanged,
            onRepeatIntervalChanged: onRepeatIntervalChanged,
          ),
        ],
      ),
    );
  }
}
