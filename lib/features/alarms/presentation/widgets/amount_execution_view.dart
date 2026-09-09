import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

class AmountExecutionView extends StatefulWidget {
  final Habit habit;
  final VoidCallback onFinish;
  final VoidCallback onSnooze;

  const AmountExecutionView({
    super.key,
    required this.habit,
    required this.onFinish,
    required this.onSnooze,
  });

  @override
  State<AmountExecutionView> createState() => _AmountExecutionViewState();
}

class _AmountExecutionViewState extends State<AmountExecutionView> {
  late Habit _currentHabit;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
  }

  void _increment(int delta) {
    HapticFeedback.selectionClick();
    HabitsRepository().incrementHabitAmount(_currentHabit.id, delta);
    final updated = HabitsRepository().getHabitById(_currentHabit.id);
    if (updated != null) {
      setState(() => _currentHabit = updated);
      if (updated.isCompleted) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  List<int> _suggestedIncrements(String? unit) {
    final u = unit?.toLowerCase() ?? '';
    if (u.contains('ml')) return [100, 250, 500];
    if (u.contains('paso')) return [500, 1000, 2000];
    if (u.contains('pag')) return [1, 5, 10];
    if (u.contains('vaso')) return [1, 2, 3];
    return [1, 5, 10];
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final current = _currentHabit.current ?? 0;
    final target = _currentHabit.target ?? 1;
    final unit = _currentHabit.unit ?? '';
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDone = current >= target;
    final increments = _suggestedIncrements(unit);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Amount counter display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$current',
                      style: textTheme.displayMedium?.copyWith(
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ $target $unit',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          // Quick increment buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: current > 0 ? () => _increment(-1) : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceHighest,
                ),
              ),
              const SizedBox(width: 8),
              ...increments.map((inc) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => _increment(inc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceHighest,
                      foregroundColor: AppColors.neonGreen,
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                      ),
                    ),
                    child: Text(
                      '+$inc',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onFinish,
            icon: Icon(isDone ? Icons.celebration_rounded : Icons.check_rounded),
            label: Text(isDone ? '¡Meta alcanzada! Listo' : 'Guardar y Salir'),
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
