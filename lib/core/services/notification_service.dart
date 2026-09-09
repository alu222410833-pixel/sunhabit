import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

/// Maneja las acciones de notificación cuando la app está terminada o en background.
///
/// Debe ser una función de nivel superior con `@pragma('vm:entry-point')` para
/// que el isolate de background del plugin pueda invocarla.
@pragma('vm:entry-point')
Future<void> _notificationBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.configureLocalTimeZone();
  await HabitsRepository().initialize();

  switch (response.actionId) {
    case 'timer_pause':
      await HabitExecutionService().restoreSession();
      HabitExecutionService().pauseTimer();
      return;
    case 'timer_resume':
      await HabitExecutionService().restoreSession();
      HabitExecutionService().resumeTimer();
      return;
    case 'timer_finish':
      await HabitExecutionService().restoreSession();
      HabitExecutionService().finishTimer();
      return;
  }

  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  final habit = HabitsRepository().getHabitById(payload);
  if (habit == null) return;

  switch (response.actionId) {
    case 'action_yes':
      await HabitsRepository().setHabitYesNo(payload, true);
      break;
    case 'action_no':
      await HabitsRepository().setHabitYesNo(payload, false);
      break;
    case 'action_add_amount':
      await HabitsRepository().incrementHabitAmount(payload, 1);
      break;
    case 'action_input_amount':
      if (response.input != null && response.input!.trim().isNotEmpty) {
        final amount = int.tryParse(response.input!.trim());
        if (amount != null && amount > 0) {
          await HabitsRepository().incrementHabitAmount(payload, amount);
        }
      }
      break;
    case 'action_snooze_10':
      await NotificationService.snoozeHabit(payload, 10);
      break;
    // action_view_checklist, action_open, action_timer_start y timer_*
    // requieren abrir la UI, así que no hacen nada en background.
  }
}

/// Servicio dedicado a las notificaciones locales usando
/// `flutter_local_notifications`.
///
/// Las notificaciones aparecen en la barra de notificaciones del sistema con
/// acciones interactivas según el tipo de hábito. A diferencia de las alarmas,
/// no abren una pantalla completa ni reproducen audio en bucle.
///
/// Usa `AndroidScheduleMode.alarmClock` (AlarmManager.setAlarmClock) para que
/// los recordatorios sigan funcionando en dispositivos Huawei/Honor/Xiaomi con
/// optimización de batería agresiva, igual que el paquete `alarm`.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'sunhabit_habit_reminders';
  static const _channelName = 'Recordatorios de SunHabit';
  static const _channelDescription = 'Notificaciones de hábitos';

  static const _timerChannelId = 'sunhabit_timer_running';
  static const _timerChannelName = 'Temporizador en curso';
  static const _timerChannelDescription = 'Notificación persistente del temporizador';

  /// Configura la zona horaria local del sistema usando `flutter_timezone`.
  static Future<void> configureLocalTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      debugPrint('[NotificationService] Local timezone configured: ${info.identifier}');
    } catch (e) {
      debugPrint('[NotificationService] Could not set local timezone, fallback: $e');
    }
  }

  static Future<void> init() async {
    await configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: iOS);
    final ok = await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _notificationBackgroundHandler,
    );
    debugPrint('[NotificationService] init ok=$ok');

    if (Platform.isAndroid) {
      await _createAndroidChannel();
    }
  }

  static Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const reminderChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
    );
    await android.createNotificationChannel(reminderChannel);

    const timerChannel = AndroidNotificationChannel(
      _timerChannelId,
      _timerChannelName,
      description: _timerChannelDescription,
      importance: Importance.defaultImportance,
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );
    await android.createNotificationChannel(timerChannel);
  }

  /// Comprueba si la aplicación puede programar alarmas y recordatorios exactos en Android.
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    return canSchedule ?? true;
  }

  /// Solicita los permisos de notificaciones del sistema.
  ///
  /// En Android también solicita:
  /// - Permiso de notificaciones (POST_NOTIFICATIONS, Android 13+).
  /// - Permiso de alarmas exactas (SCHEDULE_EXACT_ALARM, Android 12+).
  ///
  /// No pide exclusión de optimización de batería porque los recordatorios
  /// usan `setAlarmClock()`, que no es bloqueado por el ahorro de batería.
  static Future<void> requestPermissions() async {
    final notifStatus = await Permission.notification.request();
    debugPrint('[NotificationService] Permission.notification=$notifStatus');
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NotificationService] requestNotificationsPermission=$granted');
      // Pedir permiso de alarmas exactas (requerido por setAlarmClock en
      // Android 12+; USE_EXACT_ALARM en el manifest se concede automáticamente
      // en Android 13+).
      final alarmGranted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      debugPrint('[NotificationService] requestExactAlarmsPermission=$alarmGranted');
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Programa una notificación local para una fecha y hora concretas.
  ///
  /// Usa `AndroidScheduleMode.alarmClock` (que internamente utiliza
  /// `AlarmManager.setAlarmClock`) para que el recordatorio sea preciso y no
  /// sea bloqueado por la optimización de batería de Huawei/Honor/Xiaomi.
  /// Si `alarmClock` falla, intenta `exactAllowWhileIdle` y finalmente
  /// `inexactAllowWhileIdle` como fallback.
  static Future<void> schedule({
    required int id,
    required DateTime at,
    required Habit habit,
  }) async {
    final scheduled = tz.TZDateTime(
      tz.local,
      at.year,
      at.month,
      at.day,
      at.hour,
      at.minute,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('[NotificationService] skipping id=$id at=$at (already passed in local tz)');
      return;
    }

    final actions = _buildActionsForHabit(habit);
    final body = _buildBodyForHabit(habit, at);

    final imagePath = habit.effectiveImagePath;
    final largeIcon = (imagePath != null && File(imagePath).existsSync())
        ? FilePathAndroidBitmap(imagePath)
        : null;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
        ongoing: false,
        enableLights: true,
        showWhen: true,
        largeIcon: largeIcon,
        actions: actions,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Intentar alarmClock (setAlarmClock) para mayor fiabilidad en
    // Huawei/Honor/Xiaomi; si falla, probar exactos e inexactos.
    for (final mode in [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'Recordatorio',
          body: body,
          payload: habit.id,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
        debugPrint('[NotificationService] scheduled id=$id at=$at mode=$mode');
        return; // Éxito, salir del bucle.
      } on Exception catch (e) {
        debugPrint('[NotificationService] mode=$mode failed: $e');
        // Si es el último intento, re-lanzar.
        if (mode == AndroidScheduleMode.inexactAllowWhileIdle) rethrow;
        // Si no, probar el siguiente modo.
      }
    }
  }

  /// Cancela una notificación programada por su ID.
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Devuelve las notificaciones pendientes programadas. Útil para diagnosticar.
  static Future<List<PendingNotificationRequest>> pendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Pospone el recordatorio de un hábito por el número de minutos indicado.
  ///
  /// Programa la notificación pospuesta con [schedule], de forma que conserve
  /// las acciones rápidas y use `setAlarmClock()` para evitar el bloqueo por
  /// la optimización de batería de Huawei/Honor/Xiaomi.
  static Future<void> snoozeHabit(String habitId, int minutes) async {
    final habit = HabitsRepository().getHabitById(habitId);
    if (habit == null) return;

    final at = DateTime.now().add(Duration(minutes: minutes));
    final snoozeId = (habit.id.hashCode + at.minute + minutes).abs();
    await schedule(id: snoozeId, at: at, habit: habit);
  }

  // ---- Notificación persistente del temporizador ----

  static const _timerNotificationId = 888888;

  static String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static Future<void> showTimerNotification({
    required int elapsedSeconds,
    required int totalSeconds,
    required String title,
    String? habitId,
    bool isPaused = false,
  }) async {
    final remaining = totalSeconds > 0
        ? (totalSeconds - elapsedSeconds).clamp(0, totalSeconds)
        : elapsedSeconds;
    final subtitle = totalSeconds > 0
        ? '${_formatDuration(remaining)} restante (${_formatDuration(elapsedSeconds)} / ${_formatDuration(totalSeconds)})'
        : '${_formatDuration(elapsedSeconds)} transcurrido';

    final int whenMs = isPaused
        ? DateTime.now().millisecondsSinceEpoch
        : (totalSeconds > 0
            ? DateTime.now().millisecondsSinceEpoch + (remaining * 1000)
            : DateTime.now().millisecondsSinceEpoch - (elapsedSeconds * 1000));

    await _plugin.show(
      id: _timerNotificationId,
      title: isPaused ? '$title (En pausa)' : title,
      body: subtitle,
      payload: habitId ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _timerChannelId,
          _timerChannelName,
          channelDescription: _timerChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          visibility: NotificationVisibility.public,
          ongoing: !isPaused,
          onlyAlertOnce: true,
          autoCancel: false,
          usesChronometer: !isPaused,
          chronometerCountDown: !isPaused && totalSeconds > 0,
          when: whenMs,
          showWhen: true,
          actions: [
            AndroidNotificationAction(
              isPaused ? 'timer_resume' : 'timer_pause',
              isPaused ? '▶ Reanudar' : '❚❚ Pausar',
              showsUserInterface: false,
            ),
            const AndroidNotificationAction(
              'timer_finish',
              '✓ Finalizar',
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelTimerNotification() async {
    await _plugin.cancel(id: _timerNotificationId);
  }

  // ---- Acciones de notificación ----

  static void _onNotificationTapped(NotificationResponse response) {
    switch (response.actionId) {
      case 'timer_pause':
        HabitExecutionService().pauseTimer();
        return;
      case 'timer_resume':
        HabitExecutionService().resumeTimer();
        return;
      case 'timer_finish':
        HabitExecutionService().finishTimer();
        return;
    }

    final habitId = response.payload;
    if (habitId == null || habitId.isEmpty) return;

    final habit = HabitsRepository().getHabitById(habitId);
    if (habit == null) return;

    switch (response.actionId) {
      case 'action_yes':
        HabitsRepository().setHabitYesNo(habitId, true);
        break;
      case 'action_no':
        HabitsRepository().setHabitYesNo(habitId, false);
        break;
      case 'action_add_amount':
        HabitsRepository().incrementHabitAmount(habitId, 1);
        break;
      case 'action_input_amount':
        if (response.input != null && response.input!.trim().isNotEmpty) {
          final amount = int.tryParse(response.input!.trim());
          if (amount != null && amount > 0) {
            HabitsRepository().incrementHabitAmount(habitId, amount);
          }
        }
        break;
      case 'action_snooze_10':
        snoozeHabit(habitId, 10);
        break;
      case 'action_timer_start':
        HabitExecutionService().startTimer(habit);
        _openAlarmScreen(habit);
        break;
      case 'action_view_checklist':
      case 'action_open':
      default:
        _openAlarmScreen(habit);
        break;
    }
  }

  static void _openAlarmScreen(Habit habit) {
    final fakeSettings = AlarmService.instance.buildFakeAlarmSettings(habit);
    AppRouter.router.push(AppRouter.alarm, extra: fakeSettings);
  }

  // ---- Helpers ----

  static String _formatTime(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  static List<AndroidNotificationAction> _buildActionsForHabit(Habit habit) {
    switch (habit.evaluationType) {
      case HabitEvaluationType.timer:
        return const [
          AndroidNotificationAction(
            'action_timer_start',
            '▶ Iniciar',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'action_snooze_10',
            '⏰ Posponer 10m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ];
      case HabitEvaluationType.yesNo:
        return const [
          AndroidNotificationAction(
            'action_yes',
            '✓ Sí',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'action_no',
            '✕ No',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'action_snooze_10',
            '⏰ Posponer 10m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ];
      case HabitEvaluationType.checklist:
        return const [
          AndroidNotificationAction(
            'action_view_checklist',
            '📋 Ver lista',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'action_snooze_10',
            '⏰ Posponer 10m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ];
      case HabitEvaluationType.amount:
        final unitStr = habit.unit != null ? ' ${habit.unit}' : '';
        return [
          AndroidNotificationAction(
            'action_add_amount',
            '+1$unitStr',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'action_input_amount',
            '✍ Escribir',
            showsUserInterface: false,
            cancelNotification: true,
            allowGeneratedReplies: true,
            inputs: [
              AndroidNotificationActionInput(
                label: 'Ingresar cantidad${unitStr.isNotEmpty ? " en$unitStr" : ""}',
              ),
            ],
          ),
          const AndroidNotificationAction(
            'action_open',
            '📝 Abrir',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'action_snooze_10',
            '⏰ Posponer 10m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ];
    }
  }

  static String _buildBodyForHabit(Habit habit, DateTime at) {
    final time = _formatTime(at);
    switch (habit.evaluationType) {
      case HabitEvaluationType.timer:
        final min = habit.estimatedDuration?.inMinutes ?? 0;
        return '${habit.title} — $time ($min min objetivo)';
      case HabitEvaluationType.yesNo:
        return '¿${habit.title}? — $time';
      case HabitEvaluationType.checklist:
        final total = habit.checklist?.length ?? 0;
        return '${habit.title} — $time ($total tareas)';
      case HabitEvaluationType.amount:
        return '${habit.title} — $time (${habit.current ?? 0}/${habit.target ?? 0} ${habit.unit ?? ""})';
    }
  }

  /// Muestra inmediatamente una notificación local de prueba.
  ///
  /// Útil desde Ajustes para verificar que el canal y los permisos de
  /// notificaciones funcionan sin esperar a un recordatorio programado.
  static Future<void> showTestNotification() async {
    await _plugin.show(
      id: 999999,
      title: 'Notificación de prueba',
      body: 'Si ves esto, las notificaciones locales funcionan correctamente.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
