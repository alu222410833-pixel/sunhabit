import 'package:flutter/foundation.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Servicio coordinador que programa y cancela los recordatorios de hábitos.
///
/// Cada [Reminder] de un hábito puede ser de tipo 'Notificación' o 'Alarma'.
/// Este servicio decide a qué servicio delegar según el tipo:
/// - **'Notificación'** → [NotificationService] (barra de notificaciones con
///   acciones interactivas).
/// - **'Alarma'** → [AlarmService] (sonido + vibración + pantalla completa).
///
/// También se encarga de re-programar todos los recordatorios al arrancar la
/// app o al volver de background, ya que las notificaciones entregadas no se
/// re-agendan solas.
class ReminderService {
  ReminderService._internal();
  static final ReminderService instance = ReminderService._internal();

  static const int scheduleRangeDays = 14;

  /// Genera un ID único y estable para un recordatorio de un hábito en una
  /// fecha concreta. Se usa tanto para notificaciones como para alarmas.
  int idFor(Habit habit, int reminderIndex, DateTime date) {
    final raw = '${habit.id}_$reminderIndex'
        '_${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return raw.hashCode & 0x7FFFFFFF;
  }

  /// Programa todos los recordatorios de un hábito para los próximos
  /// [scheduleRangeDays] días.
  ///
  /// Primero cancela los recordatorios existentes para evitar duplicados.
  /// Usa [scheduleHabit] cuando se crea o edita un hábito.
  Future<void> scheduleHabit(Habit habit) async {
    debugPrint('[ReminderService] scheduleHabit "${habit.title}" reminders=${habit.reminders.length}');
    await cancelHabit(habit);
    final now = DateTime.now();

    for (int i = 0; i < habit.reminders.length; i++) {
      final reminder = habit.reminders[i];
      debugPrint('[ReminderService] reminder[$i] type=${reminder.type} ${reminder.hour}:${reminder.minute}');
      for (int d = 0; d < scheduleRangeDays; d++) {
        final date = now.add(Duration(days: d));
        if (!habit.isScheduledFor(date)) continue;

        if (reminder.weekDays != null && reminder.weekDays!.isNotEmpty) {
          final index = date.weekday - 1;
          if (index < 0 ||
              index >= reminder.weekDays!.length ||
              !reminder.weekDays![index]) {
            continue;
          }
        }

        final at = DateTime(
          date.year,
          date.month,
          date.day,
          reminder.hour,
          reminder.minute,
        );
        if (at.isBefore(now)) {
          debugPrint('[ReminderService] skipping $at (already passed)');
          continue;
        }

        final id = idFor(habit, i, date);
        debugPrint('[ReminderService] scheduling id=$id at=$at');
        await _scheduleOne(id: id, at: at, reminder: reminder, habit: habit, reminderIndex: i);
      }
    }
  }

  /// Re-programa los recordatorios de TODOS los hábitos sin cancelar los
  /// existentes.
  ///
  /// Se usa al arrancar la app o al volver de background. No cancela primero
  /// para no interferir con alarmas que estén a punto de sonar o sonando.
  Future<void> scheduleAllHabits() async {
    final habits = HabitsRepository().getHabits();
    final now = DateTime.now();
    for (final habit in habits) {
      if (habit.reminders.isEmpty) continue;
      for (int i = 0; i < habit.reminders.length; i++) {
        final reminder = habit.reminders[i];
        for (int d = 0; d < scheduleRangeDays; d++) {
          final date = now.add(Duration(days: d));
          if (!habit.isScheduledFor(date)) continue;

          if (reminder.weekDays != null && reminder.weekDays!.isNotEmpty) {
            final index = date.weekday - 1;
            if (index < 0 ||
                index >= reminder.weekDays!.length ||
                !reminder.weekDays![index]) {
              continue;
            }
          }

          final at = DateTime(
            date.year,
            date.month,
            date.day,
            reminder.hour,
            reminder.minute,
          );
          if (at.isBefore(now)) continue;

          final id = idFor(habit, i, date);
          await _scheduleOne(id: id, at: at, reminder: reminder, habit: habit, reminderIndex: i);
        }
      }
    }
  }

  /// Cancela todos los recordatorios futuros de un hábito.
  ///
  /// Cancela tanto en [AlarmService] como en [NotificationService] para
  /// eliminar posibles programaciones antiguas si el usuario cambia el tipo
  /// de recordatorio.
  Future<void> cancelHabit(Habit habit) async {
    final now = DateTime.now();
    for (int i = 0; i < habit.reminders.length; i++) {
      for (int d = 0; d < scheduleRangeDays; d++) {
        final date = now.add(Duration(days: d));
        final id = idFor(habit, i, date);
        await AlarmService.instance.stop(id);
        await NotificationService.cancel(id);
      }
    }
  }

  /// Delegar al servicio correspondiente según el tipo de reminder.
  ///
  /// - 'Alarma' → [AlarmService] (sonido + vibración + pantalla completa).
  /// - 'Notificación' → [NotificationService] (barra de notificaciones con
  ///   acciones rápidas según el tipo de hábito).
  ///
  /// Ambos usan `AlarmManager.setAlarmClock()`, que no es bloqueado por la
  /// optimización de batería de Huawei/Honor/Xiaomi.
  ///
  /// Antes de programar, cancela una posible programación antigua del servicio
  /// opuesto para evitar notificaciones duplicadas si el usuario cambia el
  /// tipo de recordatorio.
  Future<void> _scheduleOne({
    required int id,
    required DateTime at,
    required Reminder reminder,
    required Habit habit,
    required int reminderIndex,
  }) async {
    try {
      if (reminder.type == 'Alarma') {
        await NotificationService.cancel(id);
        await AlarmService.instance.setHabitAlarm(
          id: id,
          at: at,
          reminder: reminder,
          habit: habit,
          reminderIndex: reminderIndex,
        );
        debugPrint('[ReminderService] scheduled ALARM id=$id at=$at');
      } else {
        await AlarmService.instance.stop(id);
        await NotificationService.schedule(
          id: id,
          at: at,
          habit: habit,
        );
        debugPrint('[ReminderService] scheduled NOTIFICATION id=$id at=$at');
      }
    } on Exception catch (e) {
      debugPrint('[ReminderService] Error scheduling id=$id: $e');
    }
  }
}
