part of '../habit_detail_screen.dart';

class _HabitHistorySection extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final Color iconColor;

  const _HabitHistorySection({
    required this.habit,
    required this.logs,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _weekDays();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: AppDecorations.card,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HISTORIAL',
                    style: textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openCalendar(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver calendario',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days.map((d) => Expanded(
                  child: Center(
                    child: _DayDot(data: d, iconColor: iconColor),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 6,
                children: [
                  _LegendDot(color: iconColor, label: 'Completado'),
                  _LegendDot(color: AppColors.textMuted, label: 'No completado'),
                  _LegendDot(color: AppColors.gold, label: 'Pendiente'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_DayData> _weekDays() {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

    final map = {
      for (final l in logs) _dateOnly(l.date): l,
    };

    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final log = map[d];
      final isToday = d == today;
      final isFuture = d.isAfter(today);

      _DayStatus status;
      if (log != null && log.isCompleted) {
        status = _DayStatus.completed;
      } else if (isFuture) {
        status = _DayStatus.pending;
      } else if (isToday && !habit.isCompleted) {
        status = _DayStatus.pending;
      } else if (log != null && !log.isCompleted) {
        status = _DayStatus.notCompleted;
      } else {
        status = _DayStatus.notCompleted;
      }

      return _DayData(label: labels[i], status: status);
    });
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _openCalendar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitCalendarSheet(
        habit: habit,
        logs: logs,
        iconColor: iconColor,
      ),
    );
  }
}

enum _DayStatus { completed, notCompleted, pending }

class _DayData {
  final String label;
  final _DayStatus status;

  const _DayData({required this.label, required this.status});
}

class _DayDot extends StatelessWidget {
  final _DayData data;
  final Color iconColor;

  const _DayDot({required this.data, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (data.status) {
      _DayStatus.completed => (iconColor, Icons.check_rounded),
      _DayStatus.notCompleted => (AppColors.textMuted, null),
      _DayStatus.pending => (AppColors.gold, null),
    };

    return Column(
      children: [
        Text(
          data.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.status == _DayStatus.completed
                ? color.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: color.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: icon != null
              ? Icon(icon, color: color, size: 18)
              : null,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
