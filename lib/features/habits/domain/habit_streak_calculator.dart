import 'package:sunhabit/features/habits/data/habit_log_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

/// Calcula la racha actual y la mejor racha de un hábito a partir de su
/// historial de cumplimiento.
///
/// A diferencia de un contador simple de días consecutivos, este calculador
/// respeta la programación del hábito: un día en el que el hábito no está
/// programado no rompe la racha ni cuenta como cumplimiento.
///
/// Ejemplo: un hábito configurado para lunes, miércoles y viernes tendrá una
/// racha de 3 si completó esos tres días de la misma semana, aunque entre
/// medias haya martes y jueves en los que no estaba programado.
class HabitStreakCalculator {
  static const int _maxDaysBack = 365 * 2;

  /// Devuelve la racha actual y la mejor racha histórica.
  ///
  /// [logs] debe contener los registros del hábito (normalmente obtenidos con
  /// [HabitsRepository.getHabitLogs]). [today] permite inyectar la fecha de
  /// referencia para tests; si es null se usa [DateTime.now].
  static ({int current, int best}) calculate(
    Habit habit,
    List<HabitLog> logs, {
    DateTime? today,
  }) {
    final reference = _dateOnly(today ?? DateTime.now());
    final completedDates = logs
        .where((l) => l.isCompleted && l.habitId == habit.id)
        .map((l) => _dateOnly(l.date))
        .toSet();

    if (completedDates.isEmpty) return (current: 0, best: 0);

    final firstCompleted = completedDates.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );
    final startDate =
        habit.startDate != null ? _dateOnly(habit.startDate!) : null;

    var scanStart = startDate == null
        ? firstCompleted
        : (firstCompleted.isBefore(startDate) ? firstCompleted : startDate);

    final maxBack = reference.subtract(const Duration(days: _maxDaysBack));
    if (scanStart.isBefore(maxBack)) scanStart = maxBack;

    // Hábitos 'Algunas veces por período': la unidad de racha es el
    // período completo (semana/mes/año), no el día. Se cuenta un
    // período como cumplido si tuvo >= timesPerPeriod completados.
    if (habit.frequency == 'Algunas veces por período') {
      return _periodStreak(habit, completedDates, scanStart, reference);
    }

    final best = _bestStreak(habit, completedDates, scanStart, reference);
    final current = _currentStreak(
      habit,
      completedDates,
      reference,
      scanStart,
    );

    return (current: current, best: best);
  }

  /// Inicio del período (semana/mes/año) al que pertenece [date] según
  /// el `periodType` del hábito ('semana' por defecto).
  ///
  /// 'semana' → lunes de la semana ISO; 'mes' → día 1; 'año' → 1 de enero.
  static DateTime periodStartOf(Habit habit, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    switch (habit.periodType) {
      case 'mes':
        return DateTime(d.year, d.month);
      case 'año':
        return DateTime(d.year);
      case 'semana':
      default:
        return d.subtract(Duration(days: d.weekday - 1));
    }
  }

  /// Inicio del período siguiente a [periodStart] (que debe venir de
  /// [periodStartOf]).
  static DateTime nextPeriodStart(Habit habit, DateTime periodStart) {
    switch (habit.periodType) {
      case 'mes':
        return DateTime(periodStart.year, periodStart.month + 1);
      case 'año':
        return DateTime(periodStart.year + 1);
      case 'semana':
      default:
        return periodStart.add(const Duration(days: 7));
    }
  }

  /// Racha para frecuencias 'Algunas veces por período'.
  ///
  /// Un período está cumplido si contiene >= `timesPerPeriod` logs
  /// completados. La racha actual cuenta períodos cumplidos
  /// consecutivos hacia atrás; un período en curso aún incompleto no
  /// rompe la racha (puede completarse antes de que acabe).
  static ({int current, int best}) _periodStreak(
    Habit habit,
    Set<DateTime> completed,
    DateTime scanStart,
    DateTime reference,
  ) {
    final goal = habit.timesPerPeriod ?? 1;

    // Contar cumplimientos por período.
    final counts = <DateTime, int>{};
    for (final date in completed) {
      final start = periodStartOf(habit, date);
      counts[start] = (counts[start] ?? 0) + 1;
    }

    final currentPeriodStart = periodStartOf(habit, reference);
    final firstPeriodStart = periodStartOf(habit, scanStart);
    bool isMet(DateTime periodStart) => (counts[periodStart] ?? 0) >= goal;

    // Mejor racha: recorrer períodos en orden ascendente.
    var best = 0;
    var run = 0;
    var p = firstPeriodStart;
    while (!p.isAfter(currentPeriodStart)) {
      if (isMet(p)) {
        run++;
        if (run > best) best = run;
      } else if (!p.isAtSameMomentAs(currentPeriodStart)) {
        // Un período pasado sin cumplir rompe la racha; el período en
        // curso simplemente no se cuenta (aún puede cumplirse).
        run = 0;
      }
      p = nextPeriodStart(habit, p);
    }

    // Racha actual: hacia atrás desde el período en curso.
    var current = 0;
    p = currentPeriodStart;
    var isCurrentPeriod = true;
    while (!p.isBefore(firstPeriodStart)) {
      if (isMet(p)) {
        current++;
      } else if (!isCurrentPeriod) {
        break;
      }
      isCurrentPeriod = false;
      // Período anterior: un día antes del inicio del actual.
      p = periodStartOf(habit, p.subtract(const Duration(days: 1)));
    }

    return (current: current, best: best);
  }

  /// Recorre los días entre [start] y [end] y devuelve la mayor cantidad de
  /// días programados consecutivos completados.
  static int _bestStreak(
    Habit habit,
    Set<DateTime> completed,
    DateTime start,
    DateTime end,
  ) {
    int best = 0;
    int currentRun = 0;

    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      if (habit.isScheduledFor(d)) {
        if (completed.contains(d)) {
          currentRun++;
        } else {
          if (currentRun > best) best = currentRun;
          currentRun = 0;
        }
      }
    }

    if (currentRun > best) best = currentRun;
    return best;
  }

  /// Devuelve la racha actual: cuenta los días programados completados
  /// consecutivos hacia atrás desde el día programado más reciente.
  static int _currentStreak(
    Habit habit,
    Set<DateTime> completed,
    DateTime reference,
    DateTime minDate,
  ) {
    final lastScheduled = _lastScheduledDay(habit, reference, minDate);
    if (lastScheduled == null || !completed.contains(lastScheduled)) return 0;

    int streak = 0;
    var d = lastScheduled;
    while (!d.isBefore(minDate)) {
      if (habit.isScheduledFor(d)) {
        if (completed.contains(d)) {
          streak++;
        } else {
          break;
        }
      }
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Encuentra el día programado más reciente que no sea posterior a
  /// [reference].
  static DateTime? _lastScheduledDay(
    Habit habit,
    DateTime reference,
    DateTime minDate,
  ) {
    var d = reference;
    while (!d.isBefore(minDate)) {
      if (habit.isScheduledFor(d)) return d;
      d = d.subtract(const Duration(days: 1));
    }
    return null;
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
