import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HabitCard({super.key, required this.habit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = habit.id == '1' ? AppColors.water : AppColors.neonGreen;
    final imagePath = habit.effectiveImagePath;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.habitCard,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: AppDecorations.iconGlow(iconColor),
          child: imagePath != null
              ? HabitImageAvatar(imagePath: imagePath, size: 40)
              : Icon(
                  habit.effectiveIcon,
                  color: iconColor,
                ),
        ),
        title: Text(habit.title),
        subtitle: habit.progressText == null ? null : Text(habit.progressText!),
      ),
    );
  }
}
