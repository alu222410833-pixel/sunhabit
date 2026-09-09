import 'package:flutter/material.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/everyday_frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/month_days_frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/period_frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/repeat_frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/week_days_frequency_option.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/frequency/year_days_frequency_option.dart';

class CreateHabitFrequencyStep extends StatelessWidget {
  final String selected;
  final List<String> frequencies;
  final List<bool> weekDays;
  final List<int> monthDays;
  final List<DateTime> yearDays;
  final int timesPerPeriod;
  final String periodType;
  final int repeatInterval;
  final ValueChanged<String> onSelected;
  final ValueChanged<List<bool>> onWeekDaysChanged;
  final ValueChanged<List<int>> onMonthDaysChanged;
  final ValueChanged<List<DateTime>> onYearDaysChanged;
  final ValueChanged<int> onTimesPerPeriodChanged;
  final ValueChanged<String> onPeriodTypeChanged;
  final ValueChanged<int> onRepeatIntervalChanged;

  const CreateHabitFrequencyStep({
    super.key,
    required this.selected,
    required this.frequencies,
    required this.weekDays,
    required this.monthDays,
    required this.yearDays,
    required this.timesPerPeriod,
    required this.periodType,
    required this.repeatInterval,
    required this.onSelected,
    required this.onWeekDaysChanged,
    required this.onMonthDaysChanged,
    required this.onYearDaysChanged,
    required this.onTimesPerPeriodChanged,
    required this.onPeriodTypeChanged,
    required this.onRepeatIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: frequencies.map((freq) => _buildOptionFor(context, freq)).toList(),
    );
  }

  Widget _buildOptionFor(BuildContext context, String freq) {
    switch (freq) {
      case 'Días exactos de la semana':
        return WeekDaysFrequencyOption(
          selectedFrequency: selected,
          onSelected: onSelected,
          weekDays: weekDays,
          onChanged: onWeekDaysChanged,
        );
      case 'Días específicos del mes':
        return MonthDaysFrequencyOption(
          selectedFrequency: selected,
          onSelected: onSelected,
          monthDays: monthDays,
          onChanged: onMonthDaysChanged,
        );
      case 'Días específicos del año':
        return YearDaysFrequencyOption(
          selectedFrequency: selected,
          onSelected: onSelected,
          yearDays: yearDays,
          onChanged: onYearDaysChanged,
        );
      case 'Repetir':
        return RepeatFrequencyOption(
          selectedFrequency: selected,
          onSelected: onSelected,
          repeatInterval: repeatInterval,
          onRepeatIntervalChanged: onRepeatIntervalChanged,
        );
      case 'Algunas veces por período':
        return PeriodFrequencyOption(
          selectedFrequency: selected,
          onSelected: onSelected,
          timesPerPeriod: timesPerPeriod,
          periodType: periodType,
          repeatInterval: repeatInterval,
          onTimesChanged: onTimesPerPeriodChanged,
          onPeriodTypeChanged: onPeriodTypeChanged,
          onRepeatIntervalChanged: onRepeatIntervalChanged,
        );
      case 'Todos los días':
      default:
        return EverydayFrequencyOption(
          selectedFrequency: selected,
          onSelected: onSelected,
        );
    }
  }
}
