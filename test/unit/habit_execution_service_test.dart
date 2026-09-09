import 'dart:convert';

import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/storage_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Implementación falsa de [FlutterLocalNotificationsPlatform] que no opera
/// sobre el sistema nativo. Permite ejecutar los métodos de
/// [NotificationService] en tests de unidad sin inicializar el plugin real.
class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {}

  @override
  Future<void> cancel({required int id}) async {}
}

/// Clave usada por [HabitExecutionService] para persistir la sesión activa.
/// Se replica aquí (en lugar de importarla) porque es privada en el servicio.
const String _kSessionKey = 'active_timer_session';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    SharedPreferences.setMockInitialValues({});
    await HabitsRepository().initialize();
  });

  setUp(() async {
    // Detiene cualquier sesión activa y espera a que se completen las
    // operaciones de persistencia asíncronas pendientes.
    HabitExecutionService().stopTimer();
    await StorageService().remove(_kSessionKey);
  });

  group('HabitTimerSession serialization', () {
    test('toJson/fromJson round-trip preserves running state', () {
      final startedAt = DateTime.now();
      final session = HabitTimerSession(
        habitId: 'h1',
        habitTitle: 'Meditación',
        targetSeconds: 600,
        startedAt: startedAt,
        accumulatedSeconds: 42,
        isPaused: false,
      );

      final encoded = jsonEncode(session.toJson());
      final decoded = HabitTimerSession.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(decoded.habitId, 'h1');
      expect(decoded.habitTitle, 'Meditación');
      expect(decoded.targetSeconds, 600);
      expect(decoded.isPaused, false);
      expect(decoded.elapsedSeconds, greaterThanOrEqualTo(42));
    });

    test('toJson/fromJson preserves paused state with frozen elapsed', () {
      final session = HabitTimerSession(
        habitId: 'h2',
        habitTitle: 'Leer',
        targetSeconds: 0,
        startedAt: DateTime.now(),
        accumulatedSeconds: 120,
        isPaused: true,
      );

      final decoded = HabitTimerSession.fromJson(session.toJson());

      expect(decoded.isPaused, true);
      expect(decoded.elapsedSeconds, 120);
    });
  });

  group('HabitExecutionService persistence', () {
    test('startTimer persists habitId and startedAt', () async {
      final repo = HabitsRepository();
      final habit = Habit(
        id: 'persist_start',
        title: 'Entrenamiento',
        categoryId: 'health',
        estimatedDuration: const Duration(minutes: 45),
      );
      repo.addHabit(habit);

      HabitExecutionService().startTimer(habit);
      // startTimer dispara _persistSession() sin await; esperamos a que se
      // complete drenando la cola de microtareas.
      await Future<void>.delayed(Duration.zero);

      final stored = await StorageService().getString(_kSessionKey);
      expect(stored, isNotNull);
      final json = jsonDecode(stored!) as Map<String, dynamic>;
      expect(json['habitId'], 'persist_start');
      expect(json['startedAt'], isNotNull);
      expect(json['targetSeconds'], 45 * 60);
    });

    test('stopTimer clears persisted session', () async {
      final repo = HabitsRepository();
      final habit = Habit(
        id: 'persist_stop',
        title: 'Estudio',
        categoryId: 'study',
        estimatedDuration: const Duration(minutes: 30),
      );
      repo.addHabit(habit);

      HabitExecutionService().startTimer(habit);
      await Future<void>.delayed(Duration.zero);
      expect(await StorageService().getString(_kSessionKey), isNotNull);

      HabitExecutionService().stopTimer();
      // stopTimer dispara _clearPersistedSession() sin await.
      await Future<void>.delayed(Duration.zero);

      expect(await StorageService().getString(_kSessionKey), isNull);
    });

    test('pauseTimer persists paused flag and accumulated seconds', () async {
      final repo = HabitsRepository();
      final habit = Habit(
        id: 'persist_pause',
        title: 'Pausar',
        categoryId: 'health',
        estimatedDuration: const Duration(minutes: 10),
      );
      repo.addHabit(habit);

      HabitExecutionService().startTimer(habit);
      await Future<void>.delayed(Duration.zero);

      HabitExecutionService().pauseTimer();
      await Future<void>.delayed(Duration.zero);

      final stored = await StorageService().getString(_kSessionKey);
      expect(stored, isNotNull);
      final json = jsonDecode(stored!) as Map<String, dynamic>;
      expect(json['isPaused'], true);
      expect(json['habitId'], 'persist_pause');
    });

    test('restoreSession rebuilds an active session from storage', () async {
      final repo = HabitsRepository();
      final habit = Habit(
        id: 'persist_restore',
        title: 'Restaurar',
        categoryId: 'health',
        estimatedDuration: const Duration(minutes: 20),
      );
      repo.addHabit(habit);

      // Simula una sesión persistida por una ejecución anterior.
      await StorageService().setString(
        _kSessionKey,
        jsonEncode({
          'habitId': 'persist_restore',
          'habitTitle': 'Restaurar',
          'targetSeconds': 20 * 60,
          'startedAt': DateTime.now().toIso8601String(),
          'accumulatedSeconds': 30,
          'isPaused': false,
        }),
      );

      final restored = await HabitExecutionService().restoreSession();

      expect(restored, true);
      final session = HabitExecutionService().currentSession;
      expect(session, isNotNull);
      expect(session!.habitId, 'persist_restore');
      expect(session.isPaused, false);
      expect(session.elapsedSeconds, greaterThanOrEqualTo(30));
    });

    test('restoreSession returns false when no session stored', () async {
      final restored = await HabitExecutionService().restoreSession();
      expect(restored, false);
      expect(HabitExecutionService().currentSession, isNull);
    });

    test('restoreSession discards session for a deleted habit', () async {
      await StorageService().setString(
        _kSessionKey,
        jsonEncode({
          'habitId': 'ghost_habit',
          'habitTitle': 'Fantasma',
          'targetSeconds': 60,
          'startedAt': DateTime.now().toIso8601String(),
          'accumulatedSeconds': 0,
          'isPaused': false,
        }),
      );

      final restored = await HabitExecutionService().restoreSession();

      expect(restored, false);
      expect(HabitExecutionService().currentSession, isNull);
      expect(await StorageService().getString(_kSessionKey), isNull);
    });
  });
}
