import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/action_button.dart';

/// Panel para hábitos del tipo Sí/No.
class YesNoSection extends StatelessWidget {
  final Habit habit;
  final bool readOnly;

  const YesNoSection({super.key, required this.habit, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompleted;
    return Center(
      child: ActionButton(
        label: done ? 'Marcar como no hecho' : 'Hecho',
        icon: done ? Icons.close_rounded : Icons.check_rounded,
        color: done ? AppColors.gold : AppColors.neonGreen,
        onTap: readOnly
            ? null
            : () => HabitsRepository().setHabitYesNo(habit.id, !done),
      ),
    );
  }
}
