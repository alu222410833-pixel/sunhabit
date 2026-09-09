import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

Future<HabitEvaluationType?> showEvaluationTypePicker(
  BuildContext context, {
  required HabitEvaluationType current,
}) {
  return showModalBottomSheet<HabitEvaluationType>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tipo de objetivo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...HabitEvaluationType.values.map((type) => ListTile(
                  title: Text(evaluationLabel(type)),
                  trailing: current == type
                      ? const Icon(Icons.check, color: AppColors.neonGreen)
                      : null,
                  onTap: () => Navigator.pop(context, type),
                )),
          ],
        ),
      ),
    ),
  );
}

String evaluationLabel(HabitEvaluationType type) {
  switch (type) {
    case HabitEvaluationType.yesNo:
      return 'Sí / No';
    case HabitEvaluationType.amount:
      return 'Cantidad medible';
    case HabitEvaluationType.timer:
      return 'Cronómetro';
    case HabitEvaluationType.checklist:
      return 'Lista de objetivos';
  }
}
