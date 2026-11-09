import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

void main() {
  final service = ReminderService.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await HabitsRepository().initialize();
  });

  int epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  test('hábito diario genera un spec semanal con los 7 días', () {
    final habit = Habit(
      id: 'daily',
      title: 'Leer',
      categoryId: 'health',
      reminders: [Reminder(hour: 7, minute: 30, type: 'Alarma')],
    );
    final specs = service.buildSpecs(habit);
    expect(specs, hasLength(1));
    expect(specs.single['kind'], 'alarm');
    expect(specs.single['weekdays'], 0x7F);
    expect(specs.single['hour'], 7);
    expect(specs.single['minute'], 30);
    expect(specs.single.containsKey('dates'), isFalse);
  });

  test('cruza los días del hábito con los del recordatorio', () {
    final habit = Habit(
      id: 'weekly',
      title: 'Gym',
      categoryId: 'health',
      frequency: 'Días exactos de la semana',
      // L, M, X
      weekDays: [true, true, true, false, false, false, false],
      reminders: [
        Reminder(
          hour: 18,
          minute: 0,
          // M, X, J
          weekDays: [false, true, true, true, false, false, false],
        ),
      ],
    );
    final specs = service.buildSpecs(habit);
    expect(specs.single['kind'], 'notification');
    expect(specs.single['weekdays'], 0x6); // martes y miércoles
  });

  test('frecuencia mensual envía fechas explícitas', () {
    final now = DateTime(2026, 1, 10, 12);
    final habit = Habit(
      id: 'monthly',
      title: 'Pagar renta',
      categoryId: 'health',
      frequency: 'Días específicos del mes',
      monthDays: [1, 15],
      reminders: [Reminder(hour: 9, minute: 0)],
    );
    final dates =
        (service.buildSpecs(habit, now: now).single['dates'] as List).cast<int>();
    expect(dates.first, epochDay(DateTime(2026, 1, 15)));
    expect(dates[1], epochDay(DateTime(2026, 2, 1)));
    expect(dates.length, lessThanOrEqualTo(ReminderService.maxExplicitDates));
  });

  test('recordatorios duplicados generan un solo spec con clave estable', () {
    final habit = Habit(
      id: 'dup',
      title: 'Agua',
      categoryId: 'health',
      reminders: [Reminder(hour: 10, minute: 0), Reminder(hour: 10, minute: 0)],
    );
    final a = service.buildSpecs(habit);
    final b = service.buildSpecs(habit);
    expect(a, hasLength(1));
    expect(a.single['key'], b.single['key']);
  });

  test('sin días aplicables no genera specs', () {
    final habit = Habit(
      id: 'none',
      title: 'Nada',
      categoryId: 'health',
      frequency: 'Días exactos de la semana',
      weekDays: [true, false, false, false, false, false, false],
      reminders: [
        Reminder(
          hour: 8,
          minute: 0,
          weekDays: [false, true, false, false, false, false, false],
        ),
      ],
    );
    expect(service.buildSpecs(habit), isEmpty);
  });
}
