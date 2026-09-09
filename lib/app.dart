import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_theme.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigateToRingingAlarm();
    _alarmSub = AlarmService.instance.ringingStream.listen(_onRingingChanged);
    _startDayChangeWatcher();
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
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
      // No re-programar si hay una alarma sonando, para no interferir.
      if (AlarmService.instance.ringingAlarms.isEmpty) {
        ReminderService.instance.scheduleAllHabits();
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

  void _onRingingChanged(AlarmSet alarmSet) {
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
