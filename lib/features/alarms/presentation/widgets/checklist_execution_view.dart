import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

class ChecklistExecutionView extends StatefulWidget {
  final Habit habit;
  final VoidCallback onFinish;
  final VoidCallback onSnooze;

  const ChecklistExecutionView({
    super.key,
    required this.habit,
    required this.onFinish,
    required this.onSnooze,
  });

  @override
  State<ChecklistExecutionView> createState() => _ChecklistExecutionViewState();
}

class _ChecklistExecutionViewState extends State<ChecklistExecutionView> {
  late Habit _currentHabit;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
  }

  void _toggleItem(String item) {
    HapticFeedback.selectionClick();
    HabitsRepository().toggleChecklistItem(_currentHabit.id, item);
    final updated = HabitsRepository().getHabitById(_currentHabit.id);
    if (updated != null) {
      setState(() => _currentHabit = updated);
      if (updated.isCompleted) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = _currentHabit.checklist ?? [];
    final completedItems = _currentHabit.completedChecklist ?? [];
    final completedCount = items.where((i) => completedItems.contains(i)).length;
    final progress = items.isNotEmpty ? (completedCount / items.length) : 0.0;
    final isAllDone = items.isNotEmpty && completedCount == items.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount de ${items.length} tareas completadas',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final isDone = completedItems.contains(item);

                return GestureDetector(
                  onTap: () => _toggleItem(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.neonGreen.withValues(alpha: 0.1)
                          : AppColors.surfaceHighest,
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(
                        color: isDone
                            ? AppColors.neonGreen.withValues(alpha: 0.4)
                            : AppColors.borderDark,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone
                              ? AppColors.neonGreen
                              : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: textTheme.bodyMedium?.copyWith(
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isDone
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onFinish,
            icon: Icon(isAllDone ? Icons.celebration_rounded : Icons.check_rounded),
            label: Text(isAllDone ? '¡Completado! Listo' : 'Guardar y Salir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: const Color(0xFF152000),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onSnooze,
            icon: const Icon(Icons.snooze_rounded, size: 18),
            label: const Text('Recordar más tarde'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      );
  }
}
