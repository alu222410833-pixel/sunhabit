import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/alarm_service.dart';

/// Servicio singleton que mantiene el estado del modo cuidado visual
/// (regla 20-20-20).
///
/// Al vivir fuera del widget, el ciclo sigue corriendo aunque el usuario
/// navegue a otra pantalla. Al volver a la pantalla, el estado se restaura
/// automáticamente desde este servicio.
class EyeCareService extends ChangeNotifier {
  EyeCareService._();
  static final EyeCareService instance = EyeCareService._();

  int restSeconds = AppConstants.eyeCareBreakSeconds;
  int remaining = AppConstants.eyeCareWorkSeconds;
  bool isWorkPhase = true;
  bool running = false;
  int completedCycles = 0;

  Timer? _timer;

  /// Momento (reloj real) en el que termina la fase actual.
  /// Permite recalcular el tiempo restante al volver de background.
  DateTime? _phaseEndTime;
  int? _notificationId;

  String get _notificationTitle =>
      isWorkPhase ? 'Hora de descansar la vista' : 'Descanso terminado';

  String get _notificationBody => isWorkPhase
      ? 'Mira un objeto a 6 metros y parpadea suavemente.'
      : 'Ya puedes volver a mirar la pantalla.';

  void updateRestSeconds(int value) {
    if (running) return;
    restSeconds = value;
    if (!isWorkPhase) remaining = value;
    notifyListeners();
  }

  void toggle() {
    if (running) {
      pause();
      return;
    }
    running = true;
    _phaseEndTime = DateTime.now().add(Duration(seconds: remaining));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _scheduleUtilityNotification();
    notifyListeners();
  }

  void _tick() {
    if (remaining > 1) {
      remaining--;
      notifyListeners();
      return;
    }
    _advancePhase();
    notifyListeners();
  }

  void _advancePhase() {
    if (isWorkPhase) {
      isWorkPhase = false;
      remaining = restSeconds;
    } else {
      completedCycles++;
      isWorkPhase = true;
      remaining = AppConstants.eyeCareWorkSeconds;
    }
    _phaseEndTime = DateTime.now().add(Duration(seconds: remaining));
    _scheduleUtilityNotification();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _phaseEndTime = null;
    _cancelNotification();
    running = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _phaseEndTime = null;
    _cancelNotification();
    isWorkPhase = true;
    running = false;
    remaining = AppConstants.eyeCareWorkSeconds;
    completedCycles = 0;
    notifyListeners();
  }

  /// Recalcula el tiempo restante usando el reloj real del sistema.
  ///
  /// Se llama al volver a la pantalla o al volver de background, para corregir
  /// desvíos si el `Timer.periodic` fue pausado por el OS.
  void syncFromWallClock() {
    if (!running || _phaseEndTime == null) return;
    var diff = _phaseEndTime!.difference(DateTime.now()).inSeconds;
    while (diff <= 0) {
      _advancePhase();
      diff = _phaseEndTime!.difference(DateTime.now()).inSeconds;
    }
    remaining = diff;
    notifyListeners();
  }

  void _scheduleUtilityNotification() {
    if (!running || remaining <= 0) return;
    _notificationId = AlarmService.instance.setUtilityNotification(
      durationSeconds: remaining,
      title: _notificationTitle,
      body: _notificationBody,
    );
  }

  void _cancelNotification() {
    final id = _notificationId;
    if (id != null) {
      AlarmService.instance.cancelUtilityNotificationById(id);
      _notificationId = null;
    }
  }
}
