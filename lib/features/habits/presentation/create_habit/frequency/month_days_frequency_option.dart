import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/month_day_picker.dart';

class MonthDaysFrequencyOption extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onSelected;
  final List<int> monthDays;
  final ValueChanged<List<int>> onChanged;

  const MonthDaysFrequencyOption({
    super.key,
    required this.selectedFrequency,
    required this.onSelected,
    required this.monthDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const title = 'Días específicos del mes';
    return FrequencyOption(
      title: title,
      isSelected: selectedFrequency == title,
      onTap: () => onSelected(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona los días del mes', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          MonthDayPicker(
            monthDays: monthDays,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
