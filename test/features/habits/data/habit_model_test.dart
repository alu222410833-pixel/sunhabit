import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';

void main() {
  group('Habit.isScheduledFor', () {
    test('devuelve true para hábitos sin frecuencia configurada', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'test',
      );

      expect(habit.isScheduledFor(DateTime(2026, 8, 30)), true);
    });

    test('respeta el rango de fechas de inicio y fin', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'test',
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 8, 28),
      );

      expect(habit.isScheduledFor(DateTime(2026, 8, 24)), false);
      expect(habit.isScheduledFor(DateTime(2026, 8, 26)), true);
      expect(habit.isScheduledFor(DateTime(2026, 8, 29)), false);
    });

    test('filtra correctamente por días de la semana', () {
      // Domingo 30 de agosto de 2026 es el día 7 (weekday == 7).
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'test',
        frequency: 'Días exactos de la semana',
        weekDays: [false, false, false, false, false, false, true],
      );

      expect(habit.isScheduledFor(DateTime(2026, 8, 30)), true); // domingo
      expect(habit.isScheduledFor(DateTime(2026, 8, 29)), false); // sábado
    });

    test('filtra correctamente por días específicos del mes', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'test',
        frequency: 'Días específicos del mes',
        monthDays: [1, 15, 30],
      );

      expect(habit.isScheduledFor(DateTime(2026, 8, 30)), true);
      expect(habit.isScheduledFor(DateTime(2026, 8, 15)), true);
      expect(habit.isScheduledFor(DateTime(2026, 8, 16)), false);
    });

    test('respeta el intervalo de repetición', () {
      final habit = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'test',
        frequency: 'Repetir',
        repeatInterval: 3,
        startDate: DateTime(2026, 8, 25),
      );

      // Día 25, 28, 31...
      expect(habit.isScheduledFor(DateTime(2026, 8, 25)), true);
      expect(habit.isScheduledFor(DateTime(2026, 8, 28)), true);
      expect(habit.isScheduledFor(DateTime(2026, 8, 26)), false);
    });
  });

  group('Habit.evaluationType', () {
    test('detecta correctamente el tipo de evaluación', () {
      final yesNo = Habit(
        id: '1',
        title: 'Test',
        categoryId: 'test',
        yesNo: true,
      );
      expect(yesNo.evaluationType, HabitEvaluationType.yesNo);

      final amount = Habit(
        id: '2',
        title: 'Test',
        categoryId: 'test',
        current: 1,
        target: 5,
        unit: 'min',
      );
      expect(amount.evaluationType, HabitEvaluationType.amount);

      final checklist = Habit(
        id: '3',
        title: 'Test',
        categoryId: 'test',
        checklist: const ['Paso 1', 'Paso 2'],
      );
      expect(checklist.evaluationType, HabitEvaluationType.checklist);

      final timer = Habit(
        id: '4',
        title: 'Test',
        categoryId: 'test',
        estimatedDuration: const Duration(minutes: 10),
      );
      expect(timer.evaluationType, HabitEvaluationType.timer);
    });
  });

  group('Habit.earliestReminderMinutes', () {
    test('devuelve null si no tiene recordatorios', () {
      final habit = Habit(
        id: '1',
        title: 'Sin recordatorio',
        categoryId: 'test',
      );
      expect(habit.earliestReminderMinutes, isNull);
    });

    test('devuelve los minutos correctos para un solo recordatorio', () {
      final habit = Habit(
        id: '1',
        title: 'Recordatorio único',
        categoryId: 'test',
        reminders: const [
          Reminder(hour: 8, minute: 30),
        ],
      );
      expect(habit.earliestReminderMinutes, 8 * 60 + 30);
    });

    test('devuelve el recordatorio más temprano entre varios', () {
      final habit = Habit(
        id: '1',
        title: 'Varios recordatorios',
        categoryId: 'test',
        reminders: const [
          Reminder(hour: 14, minute: 0),
          Reminder(hour: 7, minute: 15),
          Reminder(hour: 20, minute: 45),
        ],
      );
      expect(habit.earliestReminderMinutes, 7 * 60 + 15);
    });
  });
}
