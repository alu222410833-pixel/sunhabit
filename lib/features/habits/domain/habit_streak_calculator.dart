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

    final best = _bestStreak(habit, completedDates, scanStart, reference);
    final current = _currentStreak(
      habit,
      completedDates,
      reference,
      scanStart,
    );

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
