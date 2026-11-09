import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Puente con el motor nativo de recordatorios de Android
/// (`android/app/src/main/kotlin/.../reminders/`).
///
/// El motor nativo programa cada recordatorio con
/// `AlarmManager.setAlarmClock()`, muestra la notificación o la alarma de
/// pantalla completa y reprograma la siguiente ocurrencia por sí mismo
/// (también tras reinicios o cambios de hora), sin arrancar Flutter.
///
/// En plataformas distintas de Android todas las llamadas son no-op.
class NativeReminderService {
  NativeReminderService._();

  static const _channel = MethodChannel('sunhabit/native_reminders');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Reemplaza en nativo el conjunto completo de recordatorios.
  ///
  /// [keepSnoozes] conserva los recordatorios pospuestos aún pendientes.
  /// Devuelve cuántos quedaron programados en el sistema.
  static Future<int> sync(
    List<Map<String, dynamic>> specs, {
    bool keepSnoozes = true,
  }) async {
    if (!isSupported) return specs.length;
    final count = await _channel.invokeMethod<int>('sync', {
      'specs': jsonEncode(specs),
      'keepSnoozes': keepSnoozes,
    });
    return count ?? 0;
  }

  /// Programa un recordatorio único [minutes] minutos después de ahora.
  static Future<void> snooze(Map<String, dynamic> spec, int minutes) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('snooze', {
      'spec': jsonEncode(spec),
      'minutes': minutes,
    });
  }

  /// Recordatorios con una próxima ocurrencia programada en el sistema.
  static Future<int?> scheduledCount() async {
    if (!isSupported) return null;
    return _channel.invokeMethod<int>('scheduledCount');
  }

  /// Devuelve y vacía la cola de acciones rápidas (Sí/No) pulsadas en
  /// notificaciones o en la pantalla de alarma nativa.
  static Future<List<Map<String, dynamic>>> takePendingActions() async {
    if (!isSupported) return const [];
    final raw = await _channel.invokeMethod<String>('takePendingActions');
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  /// Acción de apertura (`open` / `start_timer`) con la que una
  /// notificación o alarma abrió la app, o `null`.
  static Future<({String action, String habitId})?> takeLaunchAction() async {
    if (!isSupported) return null;
    final map = await _channel.invokeMapMethod<String, dynamic>(
        'takeLaunchAction');
    if (map == null) return null;
    return (
      action: map['action'] as String,
      habitId: map['habitId'] as String,
    );
  }

  /// Abre los ajustes de inicio automático del fabricante (Honor/Huawei/
  /// Xiaomi...) o, si no existen, los detalles de la app.
  static Future<void> openAutoStartSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<bool>('openAutoStartSettings');
  }

  /// Indica al motor en segundo plano que ya terminó (ver `nativeActionMain`).
  static Future<void> headlessDone() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('headlessDone');
  }

  /// Registra los avisos del lado nativo en el motor principal.
  static void setHandlers({
    required Future<void> Function() onPendingActions,
    required Future<void> Function() onLaunchAction,
  }) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'pendingActionsAvailable':
          await onPendingActions();
        case 'launchActionAvailable':
          await onLaunchAction();
      }
    });
  }
}
