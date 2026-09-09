import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Panel para hábitos con lista de subtareas.
class ChecklistSection extends StatelessWidget {
  final Habit habit;
  final bool readOnly;

  const ChecklistSection({
    super.key,
    required this.habit,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = habit.checklist ?? [];
    final completed = habit.completedChecklist ?? [];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Tareas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...items.map(
            (item) => CheckboxListTile(
              value: completed.contains(item),
              title: Text(item),
              activeColor: AppColors.neonGreen,
              checkColor: const Color(0xFF101600),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: readOnly
                  ? null
                  : (_) =>
                      HabitsRepository().toggleChecklistItem(habit.id, item),
            ),
          ),
        ],
      ),
    );
  }
}
