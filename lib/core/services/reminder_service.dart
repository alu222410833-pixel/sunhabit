import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/utils/stable_hash.dart';
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

  /// Cuántos días hacia adelante se escanea buscando la próxima
  /// ocurrencia fuera de la ventana rodante, para recordatorios de
  /// ciclo largo (anual, mensual o intervalos > [scheduleRangeDays]).
  /// Sin esto, un recordatorio que cae más allá de 14 días nunca se
  /// programaba si el usuario no abría la app a tiempo.
  static const int longRangeScanDays = 400;

  /// Clave estable que identifica el CONTENIDO de un recordatorio,
  /// independiente de su posición en `habit.reminders`.
  ///
  /// Antes los IDs derivaban del índice en la lista: borrar o reordenar
  /// recordatorios cambiaba la identidad de los demás y podía dejar
  /// programaciones huérfanas si alguna ruta olvidaba cancelar con el
  /// estado anterior. Dos recordatorios con contenido idéntico
  /// comparten ID — son duplicados funcionales de todos modos.
  String _reminderKey(Reminder reminder) {
    final days =
        reminder.weekDays?.map((b) => b ? '1' : '0').join() ?? '';
    return '${reminder.type}_${reminder.hour}_${reminder.minute}'
        '_${reminder.soundPath ?? ''}_${reminder.audioStartSeconds ?? ''}'
        '_${reminder.audioDurationSeconds ?? ''}_$days';
  }

  /// Genera un ID único y estable para un recordatorio de un hábito en una
  /// fecha concreta. Se usa tanto para notificaciones como para alarmas.
  ///
  /// Usa [stableHash] (FNV-1a) en lugar de `String.hashCode`, que no es
  /// estable entre ejecuciones de la app y dejaba programaciones
  /// imposibles de cancelar (alarmas fantasma/duplicadas).
  int idFor(Habit habit, Reminder reminder, DateTime date) {
    final raw = '${habit.id}_${_reminderKey(reminder)}'
        '_${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return stableHash(raw) & 0x7FFFFFFF;
  }

  /// Genera un ID único y estable para una alarma semanal de un hábito.
  ///
  /// Se usa cuando la frecuencia del hábito permite alarmas que se repiten
  /// cada 7 días (una por día de la semana activo). El `_w` distingue el ID
  /// semanal del ID diario generado por [idFor].
  int idForWeekday(Habit habit, Reminder reminder, int weekday) {
    final raw = '${habit.id}_${_reminderKey(reminder)}_w$weekday';
    return stableHash(raw) & 0x7FFFFFFF;
  }

  /// Indica si un recordatorio con `weekDays` aplica en [date].
  /// Sin `weekDays` (o lista vacía) aplica a cualquier día programado.
  bool _reminderAppliesOnDate(Reminder reminder, DateTime date) {
    final days = reminder.weekDays;
    if (days == null || days.isEmpty) return true;
    final index = date.weekday - 1;
    return index >= 0 && index < days.length && days[index];
  }

  /// Primera fecha programable DESPUÉS de la ventana rodante
  /// ([scheduleRangeDays] días), escaneando hasta [longRangeScanDays].
  ///
  /// Red de seguridad para recordatorios de ciclo largo: aunque el
  /// usuario no abra la app dentro de la ventana, la próxima ocurrencia
  /// lejana queda programada en el sistema. Devuelve `null` si el
  /// hábito no tiene más ocurrencias (p. ej. `endDate` alcanzada).
  DateTime? _nextFarOccurrence(
      Habit habit, Reminder reminder, DateTime now) {
    final end = habit.endDate;
    final endDay =
        end == null ? null : DateTime(end.year, end.month, end.day);
    for (int d = scheduleRangeDays; d <= longRangeScanDays; d++) {
      final date = now.add(Duration(days: d));
      if (endDay != null && date.isAfter(endDay)) break;
      if (!habit.isScheduledFor(date)) continue;
      if (!_reminderAppliesOnDate(reminder, date)) continue;
      return date;
    }
    return null;
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
  bool supportsWeeklyAlarms(Habit habit) {
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
    final useWeekly = supportsWeeklyAlarms(habit);

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

          final id = idForWeekday(habit, reminder, weekday);
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
          if (!_reminderAppliesOnDate(reminder, date)) continue;

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

          final id = idFor(habit, reminder, date);
          debugPrint('[ReminderService] scheduling id=$id at=$at');
          await _scheduleOne(
              id: id,
              at: at,
              reminder: reminder,
              habit: habit,
              reminderIndex: i);
        }

        // Red de seguridad para ciclos largos: programar también la
        // primera ocurrencia más allá de la ventana (anual, mensual o
        // intervalos > scheduleRangeDays), para que suene aunque la
        // app no se abra a tiempo.
        final far = _nextFarOccurrence(habit, reminder, now);
        if (far != null) {
          final at = DateTime(far.year, far.month, far.day,
              reminder.hour, reminder.minute);
          if (!at.isBefore(now)) {
            final id = idFor(habit, reminder, far);
            debugPrint('[ReminderService] scheduling far id=$id at=$at');
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
    await _migrateToStableIds();
    var scheduled = 0;
    final habits = HabitsRepository().getHabits();
    final now = DateTime.now();
    for (final habit in habits) {
      if (habit.reminders.isEmpty) continue;
      final useWeekly = supportsWeeklyAlarms(habit);
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

            final id = idForWeekday(habit, reminder, weekday);
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
            if (!_reminderAppliesOnDate(reminder, date)) continue;

            final at = DateTime(
              date.year,
              date.month,
              date.day,
              reminder.hour,
              reminder.minute,
            );
            if (at.isBefore(now)) continue;

            final id = idFor(habit, reminder, date);
            if (await _scheduleOne(
                id: id,
                at: at,
                reminder: reminder,
                habit: habit,
                reminderIndex: i)) {
              scheduled++;
            }
          }

          // Igual que en scheduleHabit: programar la primera
          // ocurrencia más allá de la ventana para ciclos largos.
          final far = _nextFarOccurrence(habit, reminder, now);
          if (far != null) {
            final at = DateTime(far.year, far.month, far.day,
                reminder.hour, reminder.minute);
            if (!at.isBefore(now)) {
              if (await _scheduleOne(
                  id: idFor(habit, reminder, far),
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
    }
    return scheduled;
  }

  /// Borra TODAS las programaciones nativas (alarmas y notificaciones)
  /// y las recrea desde cero para los hábitos actuales.
  ///
  /// Se usa tras operaciones destructivas como importar un backup:
  /// [scheduleAllHabits] nunca cancela lo que ya existe, así que los
  /// hábitos reemplazados/eliminados seguirían sonando.
  ///
  /// Devuelve el número de recordatorios programados con éxito.
  Future<int> rescheduleAllFromScratch() async {
    await Alarm.stopAll();
    await NotificationService.cancelAll();
    // El wipe también borra la notificación persistente del
    // temporizador en ejecución: hay que repintarla si hay sesión.
    HabitExecutionService().resyncActiveNotification();
    return scheduleAllHabits();
  }

  /// Clave de SharedPreferences que marca que la limpieza de
  /// programaciones con IDs inestables (basados en `String.hashCode`)
  /// ya se ejecutó.
  static const _stableIdsMigrationKey = 'stable_reminder_ids_v1';
  bool _stableIdsMigrated = false;

  /// Borra TODAS las alarmas y notificaciones programadas una sola vez.
  ///
  /// Los IDs antiguos usaban `String.hashCode`, inestable entre
  /// ejecuciones: las programaciones previas no se podían cancelar y
  /// quedaban huérfanas (o se duplicaban al reprogramar con IDs nuevos).
  /// Tras el borrado, el propio [scheduleAllHabits] reprograma todo con
  /// los nuevos IDs estables de [stableHash].
  Future<void> _migrateToStableIds() async {
    if (_stableIdsMigrated) return;
    _stableIdsMigrated = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_stableIdsMigrationKey) ?? false) return;
    await Alarm.stopAll();
    await NotificationService.cancelAll();
    // Igual que en rescheduleAllFromScratch: repintar la notificación
    // del temporizador si había una sesión activa durante el wipe.
    HabitExecutionService().resyncActiveNotification();
    await prefs.setBool(_stableIdsMigrationKey, true);
    debugPrint('[ReminderService] migración a IDs estables ejecutada');
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
      final reminder = habit.reminders[i];
      for (int weekday = 0; weekday < 7; weekday++) {
        await _safeStop(idForWeekday(habit, reminder, weekday));
        await _safeCancelNotification(
            idForWeekday(habit, reminder, weekday));
      }
      for (int d = 0; d < scheduleRangeDays; d++) {
        final date = now.add(Duration(days: d));
        await _safeStop(idFor(habit, reminder, date));
        await _safeCancelNotification(idFor(habit, reminder, date));
      }
      // Cancelar también la ocurrencia lejana programada como red de
      // seguridad para ciclos largos.
      final far = _nextFarOccurrence(habit, reminder, now);
      if (far != null) {
        final farId = idFor(habit, reminder, far);
        await _safeStop(farId);
        await _safeCancelNotification(farId);
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
