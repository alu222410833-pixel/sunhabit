import 'package:flutter/material.dart';
import 'package:sunhabit/app.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/habit_execution_service.dart';
import 'package:sunhabit/core/services/native_reminder_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Punto de entrada principal de la aplicación SunHabit.
/// Aquí se inicializan los servicios nativos y se ejecuta el widget raíz [SunHabitApp].
///
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios en orden: alarmas → notificaciones → datos.
  await AlarmService.instance.init();
  await NotificationService.init();
  await HabitsRepository().initialize();
  // Acciones Sí/No pulsadas con la app cerrada que aún no se aplicaron.
  await ReminderService.instance.applyPendingActions();
  // Solicitar permisos ANTES de programar notificaciones, de lo contrario
  // el OS descarta las notificaciones agendadas sin permiso.
  await NotificationService.requestPermissions();
  // Si hay una alarma sonando, NO re-programar para no interferir con ella.
  if (AlarmService.instance.ringingAlarms.isEmpty) {
    await ReminderService.instance.scheduleAllHabits();
  }
  // Reanuda una sesión de temporizador activa que haya sobrevivido a un
  // cierre de la app (habitId + startedAt persistidos).
  await HabitExecutionService().restoreSession();

  runApp(const SunHabitApp());
}

/// Punto de entrada del motor de Flutter en segundo plano que arranca el
/// lado nativo (`NativeRemindersChannel`) para aplicar las acciones Sí/No
/// pulsadas con la app cerrada.
@pragma('vm:entry-point')
Future<void> nativeActionMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await HabitsRepository().initialize();
    await ReminderService.instance.applyPendingActions();
  } finally {
    await NativeReminderService.headlessDone();
  }
}
