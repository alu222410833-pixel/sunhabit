import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/frequency_option.dart';

class EverydayFrequencyOption extends StatelessWidget {
  final String selectedFrequency;
  final ValueChanged<String> onSelected;

  const EverydayFrequencyOption({
    super.key,
    required this.selectedFrequency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const title = 'Todos los días';
    return FrequencyOption(
      title: title,
      isSelected: selectedFrequency == title,
      onTap: () => onSelected(title),
    );
  }
}
