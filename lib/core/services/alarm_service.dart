import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';

import 'package:sunhabit/core/utils/stable_hash.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Servicio dedicado a las alarmas nativas usando el paquete `alarm`.
///
/// Las alarmas suenan con audio + vibración y muestran una pantalla completa
/// en Android. A diferencia de las notificaciones, siguen funcionando aunque
/// la app esté cerrada porque se registran con el `AlarmManager` del OS.
class AlarmService {
  AlarmService._internal();
  static final AlarmService instance = AlarmService._internal();

  /// IDs fijos para las alarmas y notificaciones de utilidad.
  ///
  /// Cada "dueño" usa un ID único y estable entre ejecuciones. Programar
  /// con el mismo ID reemplaza la programación anterior de ese dueño (a lo
  /// sumo una pendiente por utilidad) y las cancelaciones funcionan aunque
  /// la app se reinicie — antes se usaban contadores en memoria que se
  /// reiniciaban en cada arranque y dejaban alarmas huérfanas.
  static const int utilityAlarmId = 900001;
  static const int focusTimerNotificationId = 910001;
  static const int intervalTimerNotificationId = 910002;
  static const int eyeCareNotificationId = 910003;
  static const int habitEyeCareNotificationId = 910004;
  static const int habitTimerEndNotificationId = 910005;

  /// Inicializa el paquete `alarm`. Debe llamarse en `main()` antes de usar
  /// cualquier otro método.
  Future<void> init() async {
    await Alarm.init();
  }

  /// Stream de alarmas que están sonando actualmente.
  Stream<AlarmSet> get ringingStream => Alarm.ringing;

  /// Lista de alarmas que están sonando actualmente.
  List<AlarmSettings> get ringingAlarms =>
      Alarm.ringing.value.alarms.toList();

  /// Detiene una alarma por su ID.
  Future<void> stop(int id) async {
    await Alarm.stop(id);
  }

  /// Programa una alarma nativa para un recordatorio de hábito.
  ///
  /// Usa `AlarmManager.setAlarmClock()` que NO es bloqueado por la
  /// optimización de batería de Huawei/Honor/Xiaomi.
  Future<void> setHabitAlarm({
    required int id,
    required DateTime at,
    required Reminder reminder,
    required Habit habit,
    required int reminderIndex,
  }) async {
    final timeText =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final effectiveSound =
        HabitsRepository().getEffectiveSound(habit, reminder);
    final payload = jsonEncode({
      'habitId': habit.id,
      'evaluationType': habit.evaluationType.name,
      'reminderIndex': reminderIndex,
      'reminderType': 'Alarma',
    });

    String stopLabel = 'Silenciar';
    if (habit.evaluationType == HabitEvaluationType.timer) {
      stopLabel = 'Iniciar';
    }

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: at,
        assetAudioPath: effectiveSound,
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        payload: payload,
        volumeSettings: VolumeSettings.fade(
          volume: 1.0,
          fadeDuration: const Duration(seconds: 15),
        ),
        notificationSettings: NotificationSettings(
          title: '¡Es hora de ${habit.title}!',
          body: 'Tu hábito te está esperando · $timeText',
          stopButton: stopLabel,
        ),
      ),
    );
  }

  /// Programa una notificación usando el paquete `alarm` en modo "notificación".
  ///
  /// A diferencia de [setHabitAlarm], este modo:
  /// - No reproduce audio en bucle (sin sonido o sonido corto).
  /// - No vibra.
  /// - No abre pantalla completa.
  /// - Solo muestra una notificación en la barra.
  ///
  /// Pero usa el mismo `AlarmManager.setAlarmClock()` del sistema, que NO es
  /// bloqueado por la optimización de batería. Esto es crucial en dispositivos
  /// Huawei/Honor/Xiaomi que bloquean las notificaciones de
  /// `flutter_local_notifications` pero permiten las alarmas del sistema.
  Future<void> setHabitNotification({
    required int id,
    required DateTime at,
    required Habit habit,
    required int reminderIndex,
  }) async {
    final timeText =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final payload = jsonEncode({
      'habitId': habit.id,
      'evaluationType': habit.evaluationType.name,
      'reminderIndex': reminderIndex,
      'reminderType': 'Notificación',
    });

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: at,
        assetAudioPath: null,
        loopAudio: false,
        vibrate: false,
        androidFullScreenIntent: false,
        payload: payload,
        volumeSettings: const VolumeSettings.fixed(volume: 0.0),
        notificationSettings: NotificationSettings(
          title: '¡Es hora de ${habit.title}!',
          body: 'No olvides tu hábito · $timeText',
          stopButton: 'Listo',
        ),
      ),
    );
  }

  /// Construye un [AlarmSettings] fake para navegar a la pantalla de alarma
  /// desde una notificación (que no tiene `AlarmSettings` real).
  AlarmSettings buildFakeAlarmSettings(Habit habit) {
    return AlarmSettings(
      id: stableHash(habit.id) & 0x7FFFFFFF,
      dateTime: DateTime.now(),
      assetAudioPath: null,
      loopAudio: false,
      vibrate: false,
      volumeSettings: const VolumeSettings.fixed(volume: 1.0),
      notificationSettings: NotificationSettings(
        title: habit.title,
        body: habit.title,
      ),
      payload: jsonEncode({
        'habitId': habit.id,
        'evaluationType': habit.evaluationType.name,
      }),
    );
  }

  // ---- Alarmas de utilidad (temporizador, enfoque, etc.) ----

  /// Programa una alarma nativa que sonará y vibrará cuando finalice el tiempo
  /// indicado. Se usa en los temporizadores de utilidades.
  void setUtilityAlarm({
    required int durationSeconds,
    required String title,
  }) {
    if (durationSeconds <= 0) {
      cancelUtilityAlarm();
      return;
    }

    final at = DateTime.now().add(Duration(seconds: durationSeconds));

    unawaited(Alarm.set(
      alarmSettings: AlarmSettings(
        id: utilityAlarmId,
        dateTime: at,
        loopAudio: false,
        vibrate: true,
        androidFullScreenIntent: true,
        volumeSettings: const VolumeSettings.fixed(volume: 1.0),
        notificationSettings: NotificationSettings(
          title: '¡Tiempo!',
          body: title,
        ),
      ),
    ));
  }

  /// Programa una notificación de utilidad con alerta sonora.
  ///
  /// A diferencia de [setUtilityAlarm], no vibra y no abre pantalla completa,
  /// pero usa el sonido por defecto del sistema para alertar al usuario.
  /// Incluye un botón 'Detener' para que el usuario pueda silenciarla.
  ///
  /// [id] debe ser uno de los IDs fijos por dueño (ver las constantes
  /// `*NotificationId` de esta clase); al reutilizar el mismo ID se
  /// reemplaza la programación anterior de ese dueño.
  void setUtilityNotification({
    required int id,
    required int durationSeconds,
    required String body,
    String? title,
  }) {
    if (durationSeconds <= 0) {
      cancelUtilityNotificationById(id);
      return;
    }

    final at = DateTime.now().add(Duration(seconds: durationSeconds));

    unawaited(Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: at,
        assetAudioPath: null,
        loopAudio: false,
        vibrate: false,
        androidFullScreenIntent: false,
        volumeSettings: const VolumeSettings.fixed(volume: 1.0),
        payload: jsonEncode({
          'reminderType': 'Notificación',
          'utilityType': 'utility',
        }),
        notificationSettings: NotificationSettings(
          title: title ?? '¡Tiempo!',
          body: body,
          stopButton: 'Detener',
        ),
      ),
    ));
  }

  /// Cancela una notificación de utilidad programada con [id].
  void cancelUtilityNotificationById(int id) {
    unawaited(Alarm.stop(id));
  }

  /// Cancela la alarma de utilidad actual.
  void cancelUtilityAlarm() {
    unawaited(Alarm.stop(utilityAlarmId));
  }
}
