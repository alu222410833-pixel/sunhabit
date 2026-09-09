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
