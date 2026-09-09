import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/evaluation/evaluation_segmented_control.dart';

class TimerEvaluationBody extends StatelessWidget {
  final String condition;
  final List<String> conditions;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final int hours;
  final int minutes;
  final int seconds;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  const TimerEvaluationBody({
    super.key,
    required this.condition,
    required this.conditions,
    required this.hoursController,
    required this.minutesController,
    required this.secondsController,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.onConditionChanged,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
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
        const SizedBox(height: 16),
        Text('Duración estimada', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final parsed = int.tryParse(value) ?? hours;
                  onHoursChanged(parsed);
                },
                decoration: const InputDecoration(
                  labelText: 'H.',
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final parsed = int.tryParse(value) ?? minutes;
                  onMinutesChanged(parsed);
                },
                decoration: const InputDecoration(
                  labelText: 'Min.',
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final parsed = int.tryParse(value) ?? seconds;
                  onSecondsChanged(parsed);
                },
                decoration: const InputDecoration(
                  labelText: 'Seg.',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
