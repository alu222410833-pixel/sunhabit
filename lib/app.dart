import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/native_reminder_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/services/storage_service.dart';
import 'package:sunhabit/core/theme/app_theme.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/onboarding/presentation/onboarding_screen.dart';

/// Widget raíz de la aplicación.
/// Configura el tema, las rutas y el comportamiento general de la app.
class SunHabitApp extends StatefulWidget {
  const SunHabitApp({super.key});

  @override
  State<SunHabitApp> createState() => _SunHabitAppState();
}

class _SunHabitAppState extends State<SunHabitApp> with WidgetsBindingObserver {
  StreamSubscription<AlarmSet>? _alarmSub;

  /// Timer periódico que comprueba si el día ha cambiado mientras la app
  /// está en primer plano (p. ej. si el usuario la deja abierta pasada la
  /// medianoche).
  Timer? _dayChangeTimer;

  /// Timer periódico que re-programa los recordatorios cada 6 horas mientras
  /// la app está en primer plano. Esto evita que las alarmas "expiren" si el
  /// usuario no vuelve a abrir la app dentro de [scheduleRangeDays].
  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigateToRingingAlarm();
    _alarmSub = AlarmService.instance.ringingStream.listen(_onRingingChanged);
    NativeReminderService.setHandlers(
      onPendingActions: _applyPendingReminderActions,
      onLaunchAction: _handleReminderLaunch,
    );
    WidgetsBinding.instance
        .addPostFrameCallback((_) => unawaited(_handleReminderLaunch()));
    _startDayChangeWatcher();
    _startScheduleWatcher();
    _maybeShowOnboarding();
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
    _scheduleTimer?.cancel();
    _alarmSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Al volver de background, comprobar si el día cambió mientras la app
      // estaba pausada (el Timer no se ejecuta en background).
      HabitsRepository().checkDayChange();
      unawaited(_applyPendingReminderActions());
      // El ticker del temporizador también se suspende en background:
      // resincronizar de inmediato para que la UI no muestre un tiempo
      // congelado hasta el siguiente tick (y cerrar la sesión si la
      // meta se alcanzó mientras tanto).
      HabitExecutionService().syncAfterResume();
      // No re-programar si hay una alarma sonando, para no interferir.
      if (AlarmService.instance.ringingAlarms.isEmpty) {
        unawaited(ReminderService.instance.scheduleAllHabits());
      }
    }
  }

  /// Arranca un Timer que comprueba cada 60 segundos si el día ha cambiado.
  void _startDayChangeWatcher() {
    _dayChangeTimer?.cancel();
    _dayChangeTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => HabitsRepository().checkDayChange(),
    );
  }

  /// Arranca un Timer que re-programa todos los recordatorios cada 6 horas
  /// mientras la app está en primer plano.
  ///
  /// Esto garantiza que las alarmas nunca expiren por el límite de
  /// [scheduleRangeDays] (14 días), incluso si el usuario mantiene la app
  /// abierta mucho tiempo sin ir a background.
  void _startScheduleWatcher() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) {
        // No re-programar si hay una alarma sonando, para no interferir.
        if (AlarmService.instance.ringingAlarms.isEmpty) {
          unawaited(ReminderService.instance.scheduleAllHabits());
        }
      },
    );
  }

  void _onRingingChanged(AlarmSet alarmSet) {
    // Los recordatorios de hábitos los programa y reprograma el motor
    // nativo (ver NativeReminderService); el paquete `alarm` solo queda
    // para las alarmas de utilidades.
    // Solo navegar a la pantalla de alarma para recordatorios tipo 'Alarma'.
    // Los de tipo 'Notificación' solo muestran una notificación en la barra
    // y no deben abrir la pantalla completa.
    for (final alarm in alarmSet.alarms) {
      if (_isAlarmType(alarm)) {
        _goToAlarm(alarm);
        break;
      }
    }
  }

  /// Muestra el tutorial de bienvenida la primera vez que se abre la app.
  ///
  /// El flag `onboarding_seen_v1` se persiste en [StorageService]; el
  /// tutorial también se puede re-lanzar desde Ajustes.
  void _maybeShowOnboarding() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // No interponer el tutorial si hay una alarma sonando al arrancar.
      if (AlarmService.instance.ringingAlarms.isNotEmpty) return;
      String? seen;
      try {
        seen =
            await StorageService().getString(OnboardingScreen.seenFlagKey);
      } catch (_) {
        return; // Storage no inicializado: reintentar en el próximo arranque.
      }
      if (seen == '1') return;
      await OnboardingScreen.launch();
      try {
        await StorageService()
            .setString(OnboardingScreen.seenFlagKey, '1');
      } catch (_) {
        // Si falla el guardado, el tutorial se mostrará de nuevo.
      }
    });
  }

  void _navigateToRingingAlarm() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = AlarmService.instance.ringingAlarms;
      for (final alarm in current) {
        if (_isAlarmType(alarm)) {
          _goToAlarm(alarm);
          break;
        }
      }
    });
  }

  /// Comprueba si un [AlarmSettings] es de tipo 'Alarma' (no 'Notificación').
  bool _isAlarmType(AlarmSettings settings) {
    if (settings.payload == null) return true; // sin payload, asumir alarma
    try {
      final data = jsonDecode(settings.payload!) as Map<String, dynamic>;
      return data['reminderType'] != 'Notificación';
    } on Exception {
      return true;
    }
  }

  /// Aplica las acciones Sí/No pulsadas desde notificaciones nativas.
  Future<void> _applyPendingReminderActions() =>
      ReminderService.instance.applyPendingActions();

  /// Abre el hábito cuando la app se lanzó desde un botón "Abrir",
  /// "Ver lista" o "Iniciar" de una notificación o alarma nativa.
  Future<void> _handleReminderLaunch() async {
    final launch = await NativeReminderService.takeLaunchAction();
    if (launch == null) return;
    final habit = HabitsRepository().getHabitById(launch.habitId);
    if (habit == null) return;
    if (launch.action == 'start_timer') {
      NotificationService.startTimerFromReminder(habit);
    } else {
      NotificationService.openHabitExecutionScreen(habit);
    }
  }

  void _goToAlarm(AlarmSettings settings) {
    AppRouter.router.go(AppRouter.alarm, extra: settings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SunHabit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter.router,
    );
  }
}
