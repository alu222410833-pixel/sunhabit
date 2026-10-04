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
    final accent = habit.iconColor ?? AppColors.neonGreen;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Text('Tareas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${completed.length}/${items.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) {
              final isDone = completed.contains(item);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDone
                      ? accent.withValues(alpha: 0.08)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDone
                        ? accent.withValues(alpha: 0.45)
                        : AppColors.borderDark,
                  ),
                ),
                child: CheckboxListTile(
                  value: isDone,
                  title: Text(
                    item,
                    style: isDone
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted,
                          )
                        : null,
                  ),
                  activeColor: accent,
                  checkColor: const Color(0xFF101600),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onChanged: readOnly
                      ? null
                      : (_) =>
                          HabitsRepository().toggleChecklistItem(habit.id, item),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
