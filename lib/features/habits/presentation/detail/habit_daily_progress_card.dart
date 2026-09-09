part of '../habit_detail_screen.dart';

class _HabitDailyProgressCard extends StatelessWidget {
  final String habitId;
  final int percentage;
  final Color iconColor;
  final bool isCompleted;

  const _HabitDailyProgressCard({
    required this.habitId,
    required this.percentage,
    required this.iconColor,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _openCompletionSheet(context),
      child: Container(
        decoration: AppDecorations.card,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESO DEL DÍA',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: textTheme.titleLarge?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 10,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(iconColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isCompleted ? 'Objetivo diario completado' : 'Pendiente de completar',
              style: textTheme.bodyMedium?.copyWith(
                color: isCompleted ? iconColor : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCompletionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitCompletionBottomSheet(habitId: habitId),
    );
  }
}
