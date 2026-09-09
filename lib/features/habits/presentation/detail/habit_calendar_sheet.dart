part of '../habit_detail_screen.dart';

class _HabitCalendarSheet extends StatefulWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final Color iconColor;

  const _HabitCalendarSheet({
    required this.habit,
    required this.logs,
    required this.iconColor,
  });

  @override
  State<_HabitCalendarSheet> createState() => _HabitCalendarSheetState();
}

class _HabitCalendarSheetState extends State<_HabitCalendarSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = _dateOnly(DateTime.now());
    _month = DateTime(_month.year, _month.month);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final daysInMonth = _daysInMonth(_month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final offset = firstWeekday - 1;
    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final cells = <Widget>[
      for (final l in dayLabels)
        Center(
          child: Text(
            l,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
    ];

    for (var i = 0; i < 42; i++) {
      final dayNumber = i - offset + 1;
      if (dayNumber < 1 || dayNumber > daysInMonth) {
        cells.add(const SizedBox.shrink());
      } else {
        final date = DateTime(_month.year, _month.month, dayNumber);
        cells.add(_CalendarDayCell(
          date: date,
          status: _statusFor(date),
          iconColor: widget.iconColor,
          textTheme: textTheme,
        ));
      }
    }

    return Container(
      decoration: AppDecorations.pageBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Expanded(
                      child: Text(
                        _monthName(_month),
                        style: textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  childAspectRatio: 1.05,
                  children: cells,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _LegendDot(color: widget.iconColor, label: 'Completado'),
                    _LegendDot(color: AppColors.textMuted, label: 'No completado'),
                    _LegendDot(color: AppColors.gold, label: 'Pendiente'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _CalendarCellStatus _statusFor(DateTime date) {
    final scheduled = widget.habit.isScheduledFor(date);
    if (!scheduled) return _CalendarCellStatus.empty;

    final today = _dateOnly(DateTime.now());
    if (date.isAfter(today)) return _CalendarCellStatus.pending;

    final log = widget.logs.cast<HabitLog?>().firstWhere(
      (l) => l != null && _sameDay(l.date, date),
      orElse: () => null,
    );

    if (log != null && log.isCompleted) return _CalendarCellStatus.completed;
    return _CalendarCellStatus.notCompleted;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  String _monthName(DateTime d) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${names[d.month - 1]} ${d.year}';
  }

  int _daysInMonth(DateTime d) {
    return DateTime(d.year, d.month + 1, 0).day;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

enum _CalendarCellStatus { completed, notCompleted, pending, empty }

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final _CalendarCellStatus status;
  final Color iconColor;
  final TextTheme textTheme;

  const _CalendarDayCell({
    required this.date,
    required this.status,
    required this.iconColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (status == _CalendarCellStatus.empty) {
      return Center(
        child: Text(
          '${date.day}',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    final (color, icon) = switch (status) {
      _CalendarCellStatus.completed => (iconColor, Icons.check_rounded),
      _CalendarCellStatus.notCompleted => (AppColors.textMuted, null),
      _CalendarCellStatus.pending => (AppColors.gold, null),
      _CalendarCellStatus.empty => (AppColors.textMuted, null),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.day}',
          style: textTheme.bodySmall?.copyWith(
            color: status == _CalendarCellStatus.completed
                ? iconColor
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status == _CalendarCellStatus.completed
                ? color.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: color.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: icon != null
              ? Icon(icon, color: color, size: 14)
              : null,
        ),
      ],
    );
  }
}
