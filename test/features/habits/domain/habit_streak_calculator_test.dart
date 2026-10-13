import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/habits/data/habit_log_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/domain/habit_streak_calculator.dart';

void main() {
  group('HabitStreakCalculator', () {
    test('sin logs devuelve 0, 0', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
      );

      final result = HabitStreakCalculator.calculate(habit, []);

      expect(result.current, 0);
      expect(result.best, 0);
    });

    test('racha diaria completa', () {
      final today = DateTime(2026, 9, 6);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Todos los días',
      );
      final logs = List.generate(
        5,
        (i) => HabitLog(
          habitId: '1',
          date: today.subtract(Duration(days: i)),
          isCompleted: true,
        ),
      );

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: today,
      );

      expect(result.current, 5);
      expect(result.best, 5);
    });

    test('falta un día rompe la racha actual y el histórico', () {
      final today = DateTime(2026, 9, 6);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Todos los días',
      );
      final logs = [
        HabitLog(habitId: '1', date: today, isCompleted: true),
        HabitLog(
          habitId: '1',
          date: today.subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        HabitLog(
          habitId: '1',
          date: today.subtract(const Duration(days: 3)),
          isCompleted: true,
        ),
        HabitLog(
          habitId: '1',
          date: today.subtract(const Duration(days: 4)),
          isCompleted: true,
        ),
      ];

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: today,
      );

      expect(result.current, 2);
      expect(result.best, 2);
    });

    test('hábito lunes/miércoles/viernes con racha de dos semanas', () {
      // 2026-01-05 es lunes.
      final start = DateTime(2026, 1, 5);
      final reference = DateTime(2026, 1, 19); // lunes de la tercera semana
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Días exactos de la semana',
        weekDays: [true, false, true, false, true, false, false],
        startDate: start,
      );

      final logs = <HabitLog>[];
      for (var d = start;
          !d.isAfter(reference);
          d = d.add(const Duration(days: 1))) {
        if (habit.isScheduledFor(d)) {
          logs.add(HabitLog(habitId: '1', date: d, isCompleted: true));
        }
      }

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: reference,
      );

      expect(result.current, 7);
      expect(result.best, 7);
    });

    test('día no programado usa el último día programado para la racha actual',
        () {
      // 2026-01-18 es domingo; el último día programado es viernes 16.
      final reference = DateTime(2026, 1, 18);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Días exactos de la semana',
        weekDays: [true, false, true, false, true, false, false],
      );

      final logs = [
        HabitLog(habitId: '1', date: DateTime(2026, 1, 16), isCompleted: true), // viernes
        HabitLog(habitId: '1', date: DateTime(2026, 1, 14), isCompleted: true), // miércoles
        HabitLog(habitId: '1', date: DateTime(2026, 1, 12), isCompleted: true), // lunes
        HabitLog(habitId: '1', date: DateTime(2026, 1, 9), isCompleted: false), // viernes previo
        HabitLog(habitId: '1', date: DateTime(2026, 1, 7), isCompleted: true), // miércoles previo
      ];

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: reference,
      );

      expect(result.current, 3);
      expect(result.best, 3);
    });

    test('racha por períodos: semanas con >= N cumplimientos', () {
      // Miércoles 14 de octubre de 2026; semana actual: 12-18 oct.
      final reference = DateTime(2026, 10, 14);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Algunas veces por período',
        timesPerPeriod: 3,
        periodType: 'semana',
      );

      List<HabitLog> logsOn(List<DateTime> dates) => dates
          .map((d) => HabitLog(habitId: '1', date: d, isCompleted: true))
          .toList();

      final logs = <HabitLog>[
        // Semana actual (12-18 oct): 3 cumplimientos → cumplida.
        ...logsOn([DateTime(2026, 10, 12), DateTime(2026, 10, 13), DateTime(2026, 10, 14)]),
        // Semana 5-11 oct: 3 → cumplida.
        ...logsOn([DateTime(2026, 10, 5), DateTime(2026, 10, 7), DateTime(2026, 10, 9)]),
        // Semana 28 sep-4 oct: solo 1 → fallida (rompe).
        ...logsOn([DateTime(2026, 9, 30)]),
        // Semana 21-27 sep: 3 → cumplida pero tras el fallo.
        ...logsOn([DateTime(2026, 9, 21), DateTime(2026, 9, 23), DateTime(2026, 9, 25)]),
      ];

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: reference,
      );

      expect(result.current, 2); // semana actual + anterior
      expect(result.best, 2);
    });

    test('racha por períodos: período en curso incompleto no rompe', () {
      // Miércoles 14 oct: la semana actual solo lleva 1 cumplimiento
      // (necesita 3) pero aún puede completarse → no rompe la racha.
      final reference = DateTime(2026, 10, 14);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Algunas veces por período',
        timesPerPeriod: 3,
        periodType: 'semana',
      );

      final logs = <HabitLog>[
        // Semana actual: 1 cumplimiento (incompleta, en curso).
        HabitLog(habitId: '1', date: DateTime(2026, 10, 12), isCompleted: true),
        // Dos semanas anteriores cumplidas.
        for (final d in [DateTime(2026, 10, 5), DateTime(2026, 10, 7), DateTime(2026, 10, 9)])
          HabitLog(habitId: '1', date: d, isCompleted: true),
        for (final d in [DateTime(2026, 9, 28), DateTime(2026, 9, 30), DateTime(2026, 10, 2)])
          HabitLog(habitId: '1', date: d, isCompleted: true),
      ];

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: reference,
      );

      expect(result.current, 2); // las dos semanas anteriores
      expect(result.best, 2);
    });

    test('racha por períodos: meses', () {
      final reference = DateTime(2026, 10, 15);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Algunas veces por período',
        timesPerPeriod: 2,
        periodType: 'mes',
      );

      final logs = <HabitLog>[
        // Octubre en curso: 1 (incompleto).
        HabitLog(habitId: '1', date: DateTime(2026, 10, 3), isCompleted: true),
        // Sep, Ago, Jul: 2 cada uno → cumplidos.
        for (final d in [DateTime(2026, 9, 5), DateTime(2026, 9, 20)])
          HabitLog(habitId: '1', date: d, isCompleted: true),
        for (final d in [DateTime(2026, 8, 5), DateTime(2026, 8, 20)])
          HabitLog(habitId: '1', date: d, isCompleted: true),
        for (final d in [DateTime(2026, 7, 5), DateTime(2026, 7, 20)])
          HabitLog(habitId: '1', date: d, isCompleted: true),
      ];

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: reference,
      );

      expect(result.current, 3); // jul-ago-sep
      expect(result.best, 3);
    });

    test('logs de otros hábitos se ignoran', () {
      final today = DateTime(2026, 9, 6);
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'health',
        frequency: 'Todos los días',
      );
      final logs = [
        HabitLog(habitId: '1', date: today, isCompleted: true),
        HabitLog(habitId: '2', date: today.subtract(const Duration(days: 1)), isCompleted: true),
        HabitLog(habitId: '1', date: today.subtract(const Duration(days: 2)), isCompleted: true),
      ];

      final result = HabitStreakCalculator.calculate(
        habit,
        logs,
        today: today,
      );

      expect(result.current, 1);
      expect(result.best, 1);
    });
  });
}
