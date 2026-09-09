import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class YearDayPicker extends StatefulWidget {
  final List<DateTime> yearDays;
  final ValueChanged<List<DateTime>> onChanged;

  const YearDayPicker({
    super.key,
    required this.yearDays,
    required this.onChanged,
  });

  @override
  State<YearDayPicker> createState() => _YearDayPickerState();
}

class _YearDayPickerState extends State<YearDayPicker> {
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;

  static const List<String> _monthNames = [
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

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  int _daysInMonth(int month) =>
      DateUtils.getDaysInMonth(DateTime.now().year, month);

  void _add() {
    if (widget.yearDays.length >= 10) return;
    final date = DateTime(DateTime.now().year, _selectedMonth, _selectedDay);
    final normalized = _dateOnly(date);
    final updated = List<DateTime>.from(widget.yearDays.map(_dateOnly));
    if (!updated.contains(normalized)) {
      updated.add(normalized);
      updated.sort((a, b) => a.month == b.month
          ? a.day.compareTo(b.day)
          : a.month.compareTo(b.month));
      widget.onChanged(updated);
    }
  }

  void _remove(DateTime date) {
    final normalized = _dateOnly(date);
    final updated =
        widget.yearDays.where((d) => _dateOnly(d) != normalized).toList();
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = _daysInMonth(_selectedMonth);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledDropdown<int>(
                  label: 'Mes',
                  value: _selectedMonth,
                  items: List.generate(12, (i) {
                    final month = i + 1;
                    return DropdownMenuItem(
                      value: month,
                      child: Text(_monthNames[i]),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedMonth = value;
                      if (_selectedDay > _daysInMonth(value)) {
                        _selectedDay = _daysInMonth(value);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledDropdown<int>(
                  label: 'Día',
                  value: _selectedDay,
                  items: List.generate(days, (i) {
                    final day = i + 1;
                    return DropdownMenuItem(
                      value: day,
                      child: Text('$day'),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedDay = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.yearDays.length >= 10 ? null : _add,
            child: Opacity(
              opacity: widget.yearDays.length >= 10 ? 0.5 : 1,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppColors.neonGreen),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: AppColors.neonGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Agregar fecha',
                      style: textTheme.titleMedium
                          ?.copyWith(color: AppColors.neonGreen),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.yearDays.isNotEmpty) ...[
            Text(
              '${widget.yearDays.length}/10 fechas',
              style: textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.yearDays.length,
                itemBuilder: (context, index) {
                  final date = widget.yearDays[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${date.day} de ${_monthNames[date.month - 1]}',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _remove(date),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              dropdownColor: AppColors.surfaceDark,
              style: textTheme.titleMedium,
              iconEnabledColor: AppColors.textSecondary,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
