import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/year_day_picker.dart';

class YearDaysFrequencyOption extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onSelected;
  final List<DateTime> yearDays;
  final ValueChanged<List<DateTime>> onChanged;

  const YearDaysFrequencyOption({
    super.key,
    required this.selectedFrequency,
    required this.onSelected,
    required this.yearDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const title = 'Días específicos del año';
    return FrequencyOption(
      title: title,
      isSelected: selectedFrequency == title,
      onTap: () => onSelected(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona fechas del año', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          YearDayPicker(
            yearDays: yearDays,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
