part of '../habit_detail_screen.dart';

class _HabitStatsCard extends StatelessWidget {
  final Habit habit;
  final HabitLog? todayLog;
  final Color iconColor;

  const _HabitStatsCard({
    required this.habit,
    required this.todayLog,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: _buildStatColumns(textTheme),
      ),
    );
  }

  List<Widget> _buildStatColumns(TextTheme textTheme) {
    final points = _StatColumn(
      label: 'PUNTOS',
      icon: Icons.star_rounded,
      value: '${habit.points}',
      unit: 'pts',
      color: AppColors.star,
      textTheme: textTheme,
    );

    switch (habit.evaluationType) {
      case HabitEvaluationType.yesNo:
        final done = habit.yesNo == true;
        return [
          points,
          _StatColumn(
            label: 'ESTADO',
            icon: done ? Icons.check_circle_rounded : Icons.cancel_outlined,
            value: done ? 'Sí' : 'No',
            unit: '',
            color: done ? iconColor : AppColors.textMuted,
            textTheme: textTheme,
          ),
          _StatColumn(
            label: 'HECHO HOY',
            icon: habit.isCompleted ? Icons.check_rounded : Icons.close_rounded,
            value: habit.isCompleted ? 'Sí' : 'No',
            unit: '',
            color: habit.isCompleted ? iconColor : AppColors.textMuted,
            textTheme: textTheme,
          ),
        ];
      case HabitEvaluationType.amount:
        final current = habit.current ?? 0;
        final target = habit.target ?? 0;
        final unit = habit.unit ?? '';
        return [
          points,
          _StatColumn(
            label: 'PROGRESO',
            icon: Icons.track_changes_rounded,
            value: '$current',
            unit: '/ $target${unit.isNotEmpty ? ' $unit' : ''}',
            color: iconColor,
            textTheme: textTheme,
          ),
          _StatColumn(
            label: 'META',
            icon: Icons.flag_rounded,
            value: '$target',
            unit: unit,
            color: iconColor,
            textTheme: textTheme,
          ),
        ];
      case HabitEvaluationType.checklist:
        final done = habit.completedChecklist?.length ?? 0;
        final total = habit.checklist?.length ?? 0;
        return [
          points,
          _StatColumn(
            label: 'COMPLETADAS',
            icon: Icons.check_circle_rounded,
            value: '$done',
            unit: 'de $total',
            color: iconColor,
            textTheme: textTheme,
          ),
          _StatColumn(
            label: 'TOTAL',
            icon: Icons.list_rounded,
            value: '$total',
            unit: 'tareas',
            color: iconColor,
            textTheme: textTheme,
          ),
        ];
      case HabitEvaluationType.timer:
        final estimated = habit.estimatedDuration;
        final estimatedText = estimated != null
            ? '${estimated.inMinutes} min'
            : '—';
        final completedTime = _completedTimeText();
        return [
          points,
          _StatColumn(
            label: 'DURACIÓN ESTIMADA',
            icon: Icons.timer_outlined,
            value: estimatedText.split(' ').first,
            unit: estimatedText == '—' ? '' : 'min',
            color: iconColor,
            textTheme: textTheme,
          ),
          _StatColumn(
            label: 'TIEMPO COMPLETADO',
            icon: Icons.watch_later_outlined,
            value: completedTime,
            unit: '',
            color: iconColor,
            textTheme: textTheme,
          ),
        ];
    }
  }

  String _completedTimeText() {
    if (todayLog?.currentValue != null && todayLog!.currentValue! > 0) {
      final d = Duration(seconds: todayLog!.currentValue!);
      return _formatDuration(d);
    }
    if (habit.isCompleted && habit.estimatedDuration != null) {
      return _formatDuration(habit.estimatedDuration!);
    }
    return '--:--:--';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String unit;
  final Color color;
  final TextTheme textTheme;

  const _StatColumn({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  ' $unit',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
