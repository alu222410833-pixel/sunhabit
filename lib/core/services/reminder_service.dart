import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/native_reminder_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/utils/stable_hash.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

/// Coordinador de los recordatorios de hábitos.
///
/// Traduce los [Reminder] de cada hábito a "specs" y se los envía al motor
/// nativo de Android ([NativeReminderService]), que programa cada uno con
/// `AlarmManager.setAlarmClock()` y calcula por sí mismo la siguiente
/// ocurrencia cada vez que suena, tras un reinicio o un cambio de hora.
///
/// Cada sincronización envía la lista COMPLETA de recordatorios: el lado
/// nativo cancela lo que ya no existe, así que no hace falta llevar IDs ni
/// cancelar programaciones manualmente.
class ReminderService {
  ReminderService._internal();
  static final ReminderService instance = ReminderService._internal();

  static const int scheduleRangeDays = 14;

  /// Cuántos días hacia adelante se buscan ocurrencias para frecuencias
  /// que no son semanales (mensual, anual, "Repetir"...).
  static const int longRangeScanDays = 400;

  /// Máximo de fechas explícitas enviadas por recordatorio no semanal.
  static const int maxExplicitDates = 60;

  /// Limpieza única de programaciones antiguas, compartida por todas las
  /// sincronizaciones para que se envíen a nativo en orden.
  Future<void>? _legacyMigration;

  /// Clave estable que identifica el CONTENIDO de un recordatorio,
  /// independiente de su posición en `habit.reminders`.
  String _reminderKey(Reminder reminder) {
    final days =
        reminder.weekDays?.map((b) => b ? '1' : '0').join() ?? '';
    return '${reminder.type}_${reminder.hour}_${reminder.minute}'
        '_${reminder.soundPath ?? ''}_${reminder.audioStartSeconds ?? ''}'
        '_${reminder.audioDurationSeconds ?? ''}_$days';
  }

  /// ID estable de un recordatorio en una fecha concreta.
  int idFor(Habit habit, Reminder reminder, DateTime date) {
    final raw = '${habit.id}_${_reminderKey(reminder)}'
        '_${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return stableHash(raw) & 0x7FFFFFFF;
  }

  /// ID estable de un recordatorio semanal para un día de la semana.
  int idForWeekday(Habit habit, Reminder reminder, int weekday) {
    final raw = '${habit.id}_${_reminderKey(reminder)}_w$weekday';
    return stableHash(raw) & 0x7FFFFFFF;
  }

  bool _reminderAppliesOnDate(Reminder reminder, DateTime date) {
    final days = reminder.weekDays;
    if (days == null || days.isEmpty) return true;
    final index = date.weekday - 1;
    return index >= 0 && index < days.length && days[index];
  }

  /// `true` si `isScheduledFor` depende solo del día de la semana, de modo
  /// que el motor nativo puede repetir el recordatorio indefinidamente con
  /// una máscara semanal.
  bool supportsWeeklyAlarms(Habit habit) {
    return habit.frequency == null ||
        habit.frequency == 'Todos los días' ||
        habit.frequency == 'Días exactos de la semana';
  }

  static int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static String _time(Reminder r) =>
      '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}';

  /// Máscara semanal (bit 0 = lunes) donde aplican hábito y recordatorio.
  int _weekdayMask(Habit habit, Reminder reminder) {
    var mask = 0;
    final monday = DateTime(2024, 1, 1); // lunes
    for (var i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final habitOk = habit.frequency != 'Días exactos de la semana' ||
          ((habit.weekDays?.length ?? 0) > i && habit.weekDays![i]);
      if (habitOk && _reminderAppliesOnDate(reminder, day)) mask |= 1 << i;
    }
    return mask;
  }

  /// Próximas fechas (epoch day) en que aplica un recordatorio no semanal.
  List<int> _explicitDates(Habit habit, Reminder reminder, DateTime now) {
    final dates = <int>[];
    final today = DateTime(now.year, now.month, now.day);
    for (var d = 0; d <= longRangeScanDays; d++) {
      final date = DateTime(today.year, today.month, today.day + d);
      if (!habit.isScheduledFor(date)) continue;
      if (!_reminderAppliesOnDate(reminder, date)) continue;
      dates.add(_epochDay(date));
      if (dates.length >= maxExplicitDates) break;
    }
    return dates;
  }

  String _bodyFor(Habit habit, Reminder reminder) {
    final time = _time(reminder);
    if (reminder.type == 'Alarma') {
      return 'Tu hábito te está esperando · $time';
    }
    switch (habit.evaluationType) {
      case HabitEvaluationType.timer:
        final min = habit.estimatedDuration?.inMinutes ?? 0;
        return min > 0 ? 'Objetivo: $min min · $time' : 'Hora de empezar · $time';
      case HabitEvaluationType.yesNo:
        return '¿Ya lo hiciste? · $time';
      case HabitEvaluationType.checklist:
        final total = habit.checklist?.length ?? 0;
        return '$total tareas · $time';
      case HabitEvaluationType.amount:
        final target = habit.target;
        return target != null
            ? 'Meta: $target ${habit.unit ?? ''} · $time'.replaceAll('  ', ' ')
            : 'Registra tu avance · $time';
    }
  }

  String? _existingImage(Habit habit) {
    try {
      final path = habit.effectiveImagePath;
      if (path != null && File(path).existsSync()) return path;
    } catch (_) {
      // Repositorio no inicializado (tests).
    }
    return null;
  }

  Map<String, dynamic> _baseSpec(Habit habit, Reminder reminder) {
    final isAlarm = reminder.type == 'Alarma';
    String? sound;
    if (isAlarm) {
      try {
        sound = HabitsRepository().getEffectiveSound(habit, reminder);
      } catch (_) {
        sound = null;
      }
    }
    final why = habit.whyPhrase;
    return {
      'key': '${habit.id}_${_reminderKey(reminder)}',
      'habitId': habit.id,
      'habitTitle': habit.title,
      'kind': isAlarm ? 'alarm' : 'notification',
      'evaluationType': habit.evaluationType.name,
      'hour': reminder.hour,
      'minute': reminder.minute,
      'title': isAlarm ? '¡Es hora de ${habit.title}!' : habit.title,
      'body': _bodyFor(habit, reminder),
      'soundPath': ?sound,
      'imagePath': ?_existingImage(habit),
      if (why != null && why.isNotEmpty) 'whyPhrase': why,
    };
  }

  /// Specs nativos de todos los recordatorios de [habit].
  @visibleForTesting
  List<Map<String, dynamic>> buildSpecs(Habit habit, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final specs = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final reminder in habit.reminders) {
      final spec = _baseSpec(habit, reminder);
      if (!seen.add(spec['key'] as String)) continue;
      if (supportsWeeklyAlarms(habit)) {
        final mask = _weekdayMask(habit, reminder);
        if (mask == 0) continue;
        spec['weekdays'] = mask;
        if (habit.startDate != null) {
          spec['startEpochDay'] = _epochDay(habit.startDate!);
        }
        if (habit.endDate != null) {
          spec['endEpochDay'] = _epochDay(habit.endDate!);
        }
      } else {
        final dates = _explicitDates(habit, reminder, at);
        if (dates.isEmpty) continue;
        spec['dates'] = dates;
      }
      specs.add(spec);
    }
    return specs;
  }

  /// Envía a nativo los recordatorios de [habits] (lista completa).
  Future<int> _sync(List<Habit> habits, {bool keepSnoozes = true}) async {
    final specs = [for (final h in habits) ...buildSpecs(h)];
    if (!NativeReminderService.isSupported) return specs.length;
    await (_legacyMigration ??= _migrateLegacyScheduling());
    try {
      final count =
          await NativeReminderService.sync(specs, keepSnoozes: keepSnoozes);
      debugPrint('[ReminderService] synced ${specs.length} specs, '
          '$count scheduled');
      return count;
    } on PlatformException catch (e) {
      debugPrint('[ReminderService] native sync failed: $e');
      return 0;
    }
  }

  List<Habit> _habitsWith(Habit habit) => [
        for (final h in HabitsRepository().getHabits())
          if (h.id != habit.id) h,
        habit,
      ];

  /// Programa (o reprograma) los recordatorios de [habit].
  ///
  /// [habit] reemplaza a la versión guardada en el repositorio, por si el
  /// llamador aún no la persistió.
  Future<void> scheduleHabit(Habit habit) => _sync(_habitsWith(habit));

  /// Re-sincroniza los recordatorios de TODOS los hábitos.
  ///
  /// Devuelve cuántos recordatorios quedaron programados en el sistema.
  Future<int> scheduleAllHabits() => _sync(HabitsRepository().getHabits());

  /// Igual que [scheduleAllHabits] pero descarta también los recordatorios
  /// pospuestos. Se usa tras importar un backup.
  Future<int> rescheduleAllFromScratch() =>
      _sync(HabitsRepository().getHabits(), keepSnoozes: false);

  /// Quita los recordatorios de [habit] (p. ej. al eliminarlo).
  Future<void> cancelHabit(Habit habit) => _sync([
        for (final h in HabitsRepository().getHabits())
          if (h.id != habit.id) h,
      ]);

  /// Pospone el recordatorio de [habitId] [minutes] minutos (en nativo).
  Future<void> snoozeHabit(String habitId, int minutes) async {
    final habit = HabitsRepository().getHabitById(habitId);
    if (habit == null) return;
    final reminder = habit.reminders.isNotEmpty
        ? habit.reminders.first
        : Reminder(
            hour: DateTime.now().hour, minute: DateTime.now().minute);
    final spec = _baseSpec(habit, reminder)
      ..['kind'] = 'notification'
      ..['title'] = habit.title
      ..['body'] = 'Recordatorio pospuesto ${minutes}min';
    await NativeReminderService.snooze(spec, minutes);
  }

  /// Aplica las acciones Sí/No pulsadas en notificaciones o en la
  /// pantalla de alarma nativa. Las de días anteriores se descartan.
  Future<void> applyPendingActions() async {
    final actions = await NativeReminderService.takePendingActions();
    final today = _epochDay(DateTime.now());
    for (final action in actions) {
      if (action['epochDay'] != today) continue;
      final habitId = action['habitId'] as String?;
      if (habitId == null) continue;
      switch (action['action']) {
        case 'yes':
          await HabitsRepository().setHabitYesNo(habitId, true);
        case 'no':
          await HabitsRepository().setHabitYesNo(habitId, false);
      }
    }
  }

  static const _legacyCleanupKey = 'native_reminders_v1';

  /// Una sola vez: borra las programaciones de hábitos hechas antes del
  /// motor nativo (paquete `alarm` y `flutter_local_notifications`) para
  /// que no suenen duplicadas.
  Future<void> _migrateLegacyScheduling() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyCleanupKey) ?? false) return;
    try {
      for (final alarm in await Alarm.getAlarms()) {
        if (_isLegacyHabitAlarm(alarm.payload)) await Alarm.stop(alarm.id);
      }
      await NotificationService.cancelAll();
      HabitExecutionService().resyncActiveNotification();
      await prefs.setBool(_legacyCleanupKey, true);
      debugPrint('[ReminderService] legacy reminders cleaned up');
    } catch (e) {
      _legacyMigration = null;
      debugPrint('[ReminderService] legacy cleanup failed: $e');
    }
  }

  bool _isLegacyHabitAlarm(String? payload) {
    if (payload == null) return false;
    try {
      return (jsonDecode(payload) as Map<String, dynamic>)['habitId'] != null;
    } catch (_) {
      return false;
    }
  }
}
