import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/repeat_frequency_picker.dart';

class RepeatFrequencyOption extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onSelected;
  final int repeatInterval;
  final ValueChanged<int> onRepeatIntervalChanged;

  const RepeatFrequencyOption({
    super.key,
    required this.selectedFrequency,
    required this.onSelected,
    required this.repeatInterval,
    required this.onRepeatIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    const title = 'Repetir';
    return FrequencyOption(
      title: title,
      isSelected: selectedFrequency == title,
      onTap: () => onSelected(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repetir cada', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          RepeatFrequencyPicker(
            days: repeatInterval,
            onDaysChanged: onRepeatIntervalChanged,
          ),
        ],
      ),
    );
  }
}
