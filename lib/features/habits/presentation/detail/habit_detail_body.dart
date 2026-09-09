part of '../habit_detail_screen.dart';

class _HabitDetailBody extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;

  const _HabitDetailBody({
    required this.habit,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = habit.iconColor ?? AppColors.neonGreen;
    final category = HabitsRepository().getCategoryById(habit.categoryId);
    final todayLog = _todayLog(logs);

    final progress = _dailyProgress(habit);
    final percentage = (progress * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HabitHero(
            habit: habit,
            iconColor: iconColor,
            category: category?.name,
            progress: progress,
          ),
          const SizedBox(height: 20),
          _HabitStatsCard(
            habit: habit,
            todayLog: todayLog,
            iconColor: iconColor,
          ),
          const SizedBox(height: 16),
          _HabitDailyProgressCard(
            habitId: habit.id,
            percentage: percentage,
            iconColor: iconColor,
            isCompleted: habit.isCompleted,
          ),
          const SizedBox(height: 16),
          _HabitStreaksCard(habit: habit, logs: logs, iconColor: iconColor),
          const SizedBox(height: 24),
          _HabitHistorySection(
            habit: habit,
            logs: logs,
            iconColor: iconColor,
          ),
          if (logs.isEmpty) ...[
            const SizedBox(height: 16),
            _HabitEmptyState(iconColor: iconColor),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  HabitLog? _todayLog(List<HabitLog> logs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      return logs.firstWhere(
        (l) =>
            l.date.year == today.year &&
            l.date.month == today.month &&
            l.date.day == today.day,
      );
    } catch (_) {
      return null;
    }
  }

  double _dailyProgress(Habit habit) {
    if (habit.isCompleted) return 1.0;
    if (habit.target != null && habit.target! > 0 && habit.current != null) {
      return (habit.current! / habit.target!).clamp(0.0, 1.0);
    }
    if (habit.yesNo == true) return 1.0;
    if (habit.checklist != null && habit.checklist!.isNotEmpty) {
      final done = habit.completedChecklist?.length ?? 0;
      return done / habit.checklist!.length;
    }
    return 0.0;
  }
}
