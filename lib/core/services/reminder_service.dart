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

  /// Genera un ID único y estable para una alarma semanal de un hábito.
  ///
  /// Se usa cuando la frecuencia del hábito permite alarmas que se repiten
  /// cada 7 días (una por día de la semana activo). El `_w` distingue el ID
  /// semanal del ID diario generado por [idFor].
  int idForWeekday(Habit habit, int reminderIndex, int weekday) {
    final raw = '${habit.id}_${reminderIndex}_w$weekday';
    return raw.hashCode & 0x7FFFFFFF;
  }

  /// Devuelve `true` si la frecuencia del hábito es compatible con alarmas
  /// semanales repetidas (una alarma por día de la semana activo que se
  /// auto-reprograma cada 7 días cuando suena).
  ///
  /// Las alarmas semanales solo funcionan cuando `isScheduledFor` depende
  /// exclusivamente del día de la semana, porque el `AlarmManager` repite
  /// cada 7 días sin conocer la lógica de frecuencia de la app.
  ///
  /// Para frecuencias más complejas (días del mes, repetir cada X días,
  /// fechas del año) se usa la ventana rodante de [scheduleRangeDays].
  bool _supportsWeeklyAlarms(Habit habit) {
    return habit.frequency == null ||
        habit.frequency == 'Todos los días' ||
        habit.frequency == 'Días exactos de la semana';
  }

  /// Devuelve la próxima fecha/hora para el día de la semana indicado
  /// (0=Lunes, 6=Domingo) a la hora `reminder.hour`:`reminder.minute`.
  ///
  /// Si hoy es ese día pero la hora ya pasó, devuelve el mismo día de la
  /// próxima semana.
  DateTime _nextDateWithWeekday(
      DateTime now, int weekday, Reminder reminder) {
    final today = DateTime(now.year, now.month, now.day);
    var candidate = today;

    // Avanzar hasta el próximo día de la semana objetivo.
    while (candidate.weekday - 1 != weekday) {
      candidate = candidate.add(const Duration(days: 1));
    }

    var at = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      reminder.hour,
      reminder.minute,
    );

    // Si hoy coincide pero la hora ya pasó, ir a la próxima semana.
    if (candidate.isAtSameMomentAs(today) && at.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 7));
      at = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        reminder.hour,
        reminder.minute,
      );
    }

    return at;
  }

  /// Programa todos los recordatorios de un hábito.
  ///
  /// Para hábitos con frecuencia `'Todos los días'` o `'Días exactos de la
  /// semana'` crea una alarma semanal por cada día activo (`weekday` 0-6).
  /// Cada alarma se auto-reprograma cada 7 días cuando suena (ver
  /// `SunHabitApp._onRingingChanged`).
  ///
  /// Para hábitos con otras frecuencias (`'Días específicos del mes'`,
  /// `'Repetir'`, `'Días específicos del año'`) usa la ventana rodante de
  /// [scheduleRangeDays] días.
  Future<void> scheduleHabit(Habit habit) async {
    debugPrint('[ReminderService] scheduleHabit "${habit.title}" reminders=${habit.reminders.length}');
    await cancelHabit(habit);
    final now = DateTime.now();
    final useWeekly = _supportsWeeklyAlarms(habit);

    for (int i = 0; i < habit.reminders.length; i++) {
      final reminder = habit.reminders[i];
      debugPrint('[ReminderService] reminder[$i] type=${reminder.type} ${reminder.hour}:${reminder.minute}');

      if (useWeekly) {
        for (int weekday = 0; weekday < 7; weekday++) {
          if (reminder.weekDays != null &&
              reminder.weekDays!.isNotEmpty &&
              !reminder.weekDays![weekday]) {
            continue;
          }

          final at = _nextDateWithWeekday(now, weekday, reminder);
          if (!habit.isScheduledFor(at)) continue;

          final id = idForWeekday(habit, i, weekday);
          debugPrint('[ReminderService] scheduling weekly id=$id weekday=$weekday at=$at');
          await _scheduleOne(
              id: id,
              at: at,
              reminder: reminder,
              habit: habit,
              reminderIndex: i);
        }
      } else {
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
          await _scheduleOne(
              id: id,
              at: at,
              reminder: reminder,
              habit: habit,
              reminderIndex: i);
        }
      }
    }
  }

  /// Re-programa los recordatorios de TODOS los hábitos sin cancelar los
  /// existentes.
  ///
  /// Se usa al arrancar la app o al volver de background. No cancela primero
  /// para no interferir con alarmas que estén a punto de sonar o sonando.
  ///
  /// Para hábitos con frecuencia compatible crea/actualiza las alarmas
  /// semanales (máx. 7 por recordatorio). Para los demás usa la ventana
  /// rodante de [scheduleRangeDays].
  ///
  /// Devuelve el número de recordatorios programados con éxito.
  Future<int> scheduleAllHabits() async {
    var scheduled = 0;
    final habits = HabitsRepository().getHabits();
    final now = DateTime.now();
    for (final habit in habits) {
      if (habit.reminders.isEmpty) continue;
      final useWeekly = _supportsWeeklyAlarms(habit);
      for (int i = 0; i < habit.reminders.length; i++) {
        final reminder = habit.reminders[i];

        if (useWeekly) {
          for (int weekday = 0; weekday < 7; weekday++) {
            if (reminder.weekDays != null &&
                reminder.weekDays!.isNotEmpty &&
                !reminder.weekDays![weekday]) {
              continue;
            }

            final at = _nextDateWithWeekday(now, weekday, reminder);
            if (!habit.isScheduledFor(at)) continue;

            final id = idForWeekday(habit, i, weekday);
            if (await _scheduleOne(
                id: id,
                at: at,
                reminder: reminder,
                habit: habit,
                reminderIndex: i)) {
              scheduled++;
            }
          }
        } else {
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
            if (await _scheduleOne(
                id: id,
                at: at,
                reminder: reminder,
                habit: habit,
                reminderIndex: i)) {
              scheduled++;
            }
          }
        }
      }
    }
    return scheduled;
  }

  /// Cancela todos los recordatorios futuros de un hábito.
  ///
  /// Cancela tanto en [AlarmService] como en [NotificationService] para
  /// eliminar posibles programaciones antiguas si el usuario cambia el tipo
  /// de recordatorio.
  ///
  /// Se cancelan tanto los IDs semanales (para hábitos con frecuencia
  /// compatible) como los IDs diarios de la ventana rodante (para hábitos
  /// no compatibles o programaciones antiguas). Las cancelaciones de IDs
  /// inexistentes son ignoradas.
  Future<void> cancelHabit(Habit habit) async {
    final now = DateTime.now();
    for (int i = 0; i < habit.reminders.length; i++) {
      for (int weekday = 0; weekday < 7; weekday++) {
        await _safeStop(idForWeekday(habit, i, weekday));
        await _safeCancelNotification(idForWeekday(habit, i, weekday));
      }
      for (int d = 0; d < scheduleRangeDays; d++) {
        final date = now.add(Duration(days: d));
        await _safeStop(idFor(habit, i, date));
        await _safeCancelNotification(idFor(habit, i, date));
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
  Future<bool> _scheduleOne({
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
      return true;
    } on Exception catch (e) {
      debugPrint('[ReminderService] Error scheduling id=$id: $e');
      return false;
    }
  }

  Future<void> _safeStop(int id) async {
    try {
      await AlarmService.instance.stop(id);
    } catch (_) {
      // Ignorar: la alarma puede no existir.
    }
  }

  Future<void> _safeCancelNotification(int id) async {
    try {
      await NotificationService.cancel(id);
    } catch (_) {
      // Ignorar: la notificación puede no existir.
    }
  }
}
