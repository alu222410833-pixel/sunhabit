import 'package:flutter_test/flutter_test.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

import '../../../helpers/fake_storage_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('HabitsRepository', () {
    late FakeStorageService storage;

    setUp(() {
      storage = FakeStorageService();
    });

    test('carga hábitos por defecto cuando el almacenamiento está vacío',
        () async {
      final repository = HabitsRepository.test(storage);
      await repository.initialize();

      final habits = repository.getHabits();
      expect(habits, isNotEmpty);
      expect(repository.getHabitById('1'), isNotNull);
    });

    test('setHabitAmount clampa el valor entre 0 y 999999', () async {
      final repository = HabitsRepository.test(storage);
      await repository.initialize();

      // Valor negativo → 0.
      repository.setHabitAmount('1', -50);
      expect(repository.getHabitById('1')?.current, 0);

      // Valor excesivo → 999999.
      repository.setHabitAmount('1', 10000000);
      expect(repository.getHabitById('1')?.current, 999999);
      expect(repository.getHabitById('1')?.isCompleted, true);
    });

    test('completeHabitWithDuration guarda los segundos en el log', () async {
      final repository = HabitsRepository.test(storage);
      await repository.initialize();

      repository.completeHabitWithDuration('2', 123);

      final habit = repository.getHabitById('2');
      expect(habit, isNotNull);
      expect(habit!.isCompleted, true);

      final logs = repository.getHabitLogs('2');
      expect(logs, isNotEmpty);
      expect(logs.last.currentValue, 123);
    });

    test('getHabitsForDate ordena los incompletos por hora y los completados al final',
        () async {
      final repository = HabitsRepository.test(storage);
      await repository.initialize();

      // Limpiamos los hábitos por defecto para probar nuestro conjunto específico
      for (final h in repository.getHabits()) {
        repository.deleteHabit(h.id);
      }

      final hTarde = Habit(
        id: 'h_tarde',
        title: 'Hábito Tarde',
        categoryId: 'health',
        reminders: const [Reminder(hour: 20, minute: 0)],
      );
      final hManana = Habit(
        id: 'h_manana',
        title: 'Hábito Mañana',
        categoryId: 'health',
        reminders: const [Reminder(hour: 8, minute: 0)],
      );
      final hSinHora = Habit(
        id: 'h_sin_hora',
        title: 'Hábito Sin Hora',
        categoryId: 'health',
      );
      final hCompletadoTemprano = Habit(
        id: 'h_comp_temprano',
        title: 'Hábito Completado Temprano',
        categoryId: 'health',
        reminders: const [Reminder(hour: 6, minute: 0)],
      );

      repository.addHabit(hTarde);
      repository.addHabit(hManana);
      repository.addHabit(hSinHora);
      repository.addHabit(hCompletadoTemprano);

      // Completamos el hábito temprano
      repository.completeHabit('h_comp_temprano');

      final today = DateTime.now();
      final habitsToday = repository.getHabitsForDate(today);

      // Esperamos:
      // 1. hManana (08:00, incompleto)
      // 2. hTarde (20:00, incompleto)
      // 3. hSinHora (sin recordatorio, incompleto)
      // 4. hCompletadoTemprano (06:00, completado)
      expect(habitsToday.map((h) => h.id).toList(), [
        'h_manana',
        'h_tarde',
        'h_sin_hora',
        'h_comp_temprano',
      ]);
    });
  });
}
