import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/presentation/edit_habit/widgets/edit_habit_time_field.dart';

Future<void> showGoalEditor(
  BuildContext context, {
  required HabitEvaluationType evaluationType,
  required TextEditingController targetController,
  required List<String> units,
  required String unit,
  required int timerHours,
  required int timerMinutes,
  required int timerSeconds,
  required TextEditingController timerHoursController,
  required TextEditingController timerMinutesController,
  required TextEditingController timerSecondsController,
  required void Function(int target) onTargetChanged,
  required void Function(String unit) onUnitChanged,
  required void Function() onTimerUpdated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        var localUnit = unit;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Objetivo diario', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (evaluationType == HabitEvaluationType.yesNo) ...[
                const ListTile(
                  title: Text('Marcar como completado'),
                  subtitle: Text('Sin meta numérica'),
                ),
              ] else if (evaluationType == HabitEvaluationType.amount) ...[
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Meta'),
                  onChanged: (v) {
                    final n = int.tryParse(v) ?? 1;
                    onTargetChanged(n);
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Unidad'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: localUnit,
                      isDense: true,
                      dropdownColor: AppColors.surfaceDark,
                      items: units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => localUnit = v);
                        onUnitChanged(v);
                      },
                    ),
                  ),
                ),
              ] else if (evaluationType == HabitEvaluationType.timer) ...[
                Row(
                  children: [
                    EditHabitTimeField(
                      label: 'H',
                      controller: timerHoursController,
                      onChanged: (v) => onTimerUpdated(),
                    ),
                    const Text(':', style: TextStyle(fontSize: 20)),
                    EditHabitTimeField(
                      label: 'M',
                      controller: timerMinutesController,
                      onChanged: (v) => onTimerUpdated(),
                    ),
                    const Text(':', style: TextStyle(fontSize: 20)),
                    EditHabitTimeField(
                      label: 'S',
                      controller: timerSecondsController,
                      onChanged: (v) => onTimerUpdated(),
                    ),
                  ],
                ),
              ] else if (evaluationType == HabitEvaluationType.checklist) ...[
                const ListTile(
                  title: Text('Usa objetivos adicionales'),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
