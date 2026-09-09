import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/week_day_picker.dart';

class WeekDaysFrequencyOption extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onSelected;
  final List<bool> weekDays;
  final ValueChanged<List<bool>> onChanged;

  const WeekDaysFrequencyOption({
    super.key,
    required this.selectedFrequency,
    required this.onSelected,
    required this.weekDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const title = 'Días exactos de la semana';
    return FrequencyOption(
      title: title,
      isSelected: selectedFrequency == title,
      onTap: () => onSelected(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona los días', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          WeekDayPicker(
            weekDays: weekDays,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
