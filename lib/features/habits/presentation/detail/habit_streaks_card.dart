part of '../habit_detail_screen.dart';

class _HabitStreaksCard extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final Color iconColor;

  const _HabitStreaksCard({
    required this.habit,
    required this.logs,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final streaks = HabitStreakCalculator.calculate(habit, logs);
    final current = streaks.current;
    final best = streaks.best;

    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          _StreakColumn(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.fire,
            label: 'RACHA ACTUAL',
            value: '$current',
            unit: current == 1 ? 'día' : 'días',
            footer: '¡Sigue así!',
            textTheme: textTheme,
          ),
          const VerticalDivider(
            color: AppColors.borderDark,
            thickness: 1,
            width: 16,
            indent: 8,
            endIndent: 8,
          ),
          _StreakColumn(
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.gold,
            label: 'MEJOR RACHA',
            value: '$best',
            unit: best == 1 ? 'día' : 'días',
            footer: 'Tu récord personal',
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

}

class _StreakColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String footer;
  final TextTheme textTheme;

  const _StreakColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.footer,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            footer,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
