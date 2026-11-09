import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/habit_completion_bottom_sheet/habit_completion_bottom_sheet.dart';

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

  /// Cancela una notificación programada por su ID.
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancela TODAS las notificaciones programadas.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Devuelve las notificaciones pendientes programadas. Útil para diagnosticar.
  static Future<List<PendingNotificationRequest>> pendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Pospone el recordatorio de un hábito (lo programa el motor nativo).
  static Future<void> snoozeHabit(String habitId, int minutes) =>
      ReminderService.instance.snoozeHabit(habitId, minutes);

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
    // Mientras corre, el cronómetro nativo ya muestra el tiempo en vivo;
    // el cuerpo solo indica el objetivo para no duplicar un tiempo estático
    // que quedaría desactualizado. En pausa no hay cronómetro, así que el
    // cuerpo sí muestra el progreso (correcto al ser un valor fijo).
    final String subtitle;
    if (isPaused) {
      subtitle = totalSeconds > 0
          ? '${_formatDuration(elapsedSeconds.clamp(0, totalSeconds))} / ${_formatDuration(totalSeconds)}'
          : '${_formatDuration(elapsedSeconds)} transcurrido';
    } else {
      subtitle = totalSeconds > 0
          ? 'Objetivo: ${_formatDuration(totalSeconds)}'
          : 'Cronómetro en curso';
    }

    final int whenMs = isPaused
        ? DateTime.now().millisecondsSinceEpoch
        : (totalSeconds > 0
            ? DateTime.now().millisecondsSinceEpoch + (remaining * 1000)
            : DateTime.now().millisecondsSinceEpoch - (elapsedSeconds * 1000));

    // Auto-cancelar la notificación justo cuando el cronómetro llega a
    // cero. Si el proceso muere en segundo plano nadie ejecuta finishTimer,
    // y sin esto el cronómetro seguiría contando en negativo.
    final int? timeoutMs =
        (!isPaused && totalSeconds > 0 && remaining > 0)
            ? remaining * 1000
            : null;

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
          timeoutAfter: timeoutMs,
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
      case 'timer_resume':
      case 'timer_finish':
        unawaited(_handleTimerAction(response.actionId!));
        return;
    }

    final habitId = response.payload;
    if (habitId == null || habitId.isEmpty) return;

    final habit = HabitsRepository().getHabitById(habitId);
    if (habit == null) return;

    String? feedbackMessage;

    switch (response.actionId) {
      case 'action_yes':
        HabitsRepository().setHabitYesNo(habitId, true);
        feedbackMessage = '✓ "${habit.title}" marcado como completado';
        break;
      case 'action_no':
        HabitsRepository().setHabitYesNo(habitId, false);
        feedbackMessage = '✗ "${habit.title}" marcado como no completado';
        break;
      case 'action_add_amount':
        HabitsRepository().incrementHabitAmount(habitId, 1);
        feedbackMessage = '+1 "${habit.title}"';
        break;
      case 'action_input_amount':
        if (response.input != null && response.input!.trim().isNotEmpty) {
          final amount = int.tryParse(response.input!.trim());
          if (amount != null && amount > 0) {
            HabitsRepository().incrementHabitAmount(habitId, amount);
            feedbackMessage = '+$amount "${habit.title}"';
          }
        }
        break;
      case 'action_snooze_10':
        snoozeHabit(habitId, 10);
        feedbackMessage = '⏰ "${habit.title}" pospuesto 10 min';
        break;
      case 'action_timer_start':
        startTimerFromReminder(habit);
        return;
      case 'action_view_checklist':
      case 'action_open':
      default:
        // Las notificaciones abren la pantalla de ejecución del hábito,
        // no la pantalla de alarma. La pantalla de alarma solo se abre
        // cuando una alarma real está sonando.
        openHabitExecutionScreen(habit);
        return;
    }

    // Mostrar feedback visual si la app está en foreground
    if (feedbackMessage != null) {
      _showFeedback(feedbackMessage);
    }
  }

  /// Muestra un snackbar con feedback de la acción ejecutada.
  /// Solo funciona si la app está en foreground y hay un Scaffold disponible.
  static void _showFeedback(String message) {
    try {
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(message),
          ),
        );
    } catch (e) {
      debugPrint('[NotificationService] Error showing feedback: $e');
    }
  }

  /// Inicia el temporizador del hábito y abre su pantalla de ejecución.
  static void startTimerFromReminder(Habit habit) {
    HabitExecutionService().startTimer(habit);
    _openAlarmScreen(habit);
  }

  static void _openAlarmScreen(Habit habit) {
    final fakeSettings = AlarmService.instance.buildFakeAlarmSettings(habit);
    AppRouter.router.push(AppRouter.alarm, extra: fakeSettings);
  }

  /// Abre la pantalla de registro del hábito (cantidad, checklist,
  /// temporizador, sí/no) — el mismo sheet que se abre al tocar el
  /// hábito en Inicio.
  static void openHabitExecutionScreen(Habit habit) {
    AppRouter.router.go('/');
    // La navegación necesita un frame para montar el Navigator; si el
    // contexto aún no existe (arranque en frío) se reintenta una vez.
    void open() {
      final ctx =
          AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (ctx == null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final retryCtx =
              AppRouter.router.routerDelegate.navigatorKey.currentContext;
          if (retryCtx == null || !retryCtx.mounted) return;
          _showHabitSheet(retryCtx, habit);
        });
        return;
      }
      if (!ctx.mounted) return;
      _showHabitSheet(ctx, habit);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => open());
  }

  static void _showHabitSheet(BuildContext context, Habit habit) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitCompletionBottomSheet(habitId: habit.id),
    );
  }

  /// Acciones del temporizador desde la notificación en foreground.
  ///
  /// Si la acción llega en un arranque en frío, la sesión aún no está en
  /// memoria y llamar a pause/resume/finish la tragaría en silencio: la
  /// notificación seguiría contando aunque el usuario pulsó "Pausar".
  /// Se restaura la sesión primero (no-op si ya hay una viva).
  static Future<void> _handleTimerAction(String actionId) async {
    await HabitExecutionService().restoreSession();
    switch (actionId) {
      case 'timer_pause':
        HabitExecutionService().pauseTimer();
        break;
      case 'timer_resume':
        HabitExecutionService().resumeTimer();
        break;
      case 'timer_finish':
        HabitExecutionService().finishTimer();
        break;
    }
  }

  // ---- Helpers ----

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
