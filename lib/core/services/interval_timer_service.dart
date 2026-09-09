import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sunhabit/core/services/alarm_service.dart';

/// Servicio singleton que mantiene el estado del temporizador de intervalos.
///
/// Al vivir fuera del widget, el timer sigue corriendo aunque el usuario
/// navegue a otra pantalla. Al volver a la pantalla de intervalos, el estado
/// se restaura automáticamente desde este servicio.
class IntervalTimerService extends ChangeNotifier {
  IntervalTimerService._();
  static final IntervalTimerService instance = IntervalTimerService._();

  int workSeconds = 45;
  int restSeconds = 15;
  int rounds = 8;

  int currentRound = 1;
  int remaining = 45;
  bool isWork = true;
  bool running = false;
  bool finished = false;

  Timer? _timer;

  /// Momento (reloj real) en el que termina la fase actual.
  /// Permite recalcular el tiempo restante al volver de background.
  DateTime? _phaseEndTime;

  String get phaseLabel =>
      isWork ? 'Intervalos - actividad' : 'Intervalos - descanso';

  String get _notificationTitle {
    if (isWork) return 'Tiempo de descansar';
    if (currentRound < rounds) return 'Tiempo de trabajar';
    return 'Entrenamiento completado';
  }

  String get _notificationBody {
    if (isWork) {
      if (currentRound < rounds) {
        return 'Terminó la actividad. Descansa antes de la siguiente ronda.';
      }
      return 'Terminó la actividad. Descansa para finalizar el entrenamiento.';
    }
    if (currentRound < rounds) {
      return 'Terminó el descanso. Es momento de trabajar.';
    }
    return 'Terminaste todas las rondas. ¡Bien hecho!';
  }

  void updateWork(int value) {
    if (running) return;
    workSeconds = value;
    if (isWork) remaining = value;
    notifyListeners();
  }

  void updateRest(int value) {
    if (running) return;
    restSeconds = value;
    if (!isWork) remaining = value;
    notifyListeners();
  }

  void updateRounds(int value) {
    if (running) return;
    rounds = value;
    if (currentRound > rounds) currentRound = rounds;
    notifyListeners();
  }

  void toggle() {
    if (running) {
      pause();
      return;
    }
    if (finished) reset();
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

    if (isWork) {
      isWork = false;
      remaining = restSeconds;
      _phaseEndTime = DateTime.now().add(Duration(seconds: restSeconds));
      _scheduleUtilityNotification();
    } else if (currentRound < rounds) {
      currentRound++;
      isWork = true;
      remaining = workSeconds;
      _phaseEndTime = DateTime.now().add(Duration(seconds: workSeconds));
      _scheduleUtilityNotification();
    } else {
      _timer?.cancel();
      _timer = null;
      running = false;
      finished = true;
      remaining = 0;
      _phaseEndTime = null;
    }
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _phaseEndTime = null;
    AlarmService.instance.cancelUtilityNotification();
    running = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _phaseEndTime = null;
    AlarmService.instance.cancelUtilityNotification();
    currentRound = 1;
    isWork = true;
    remaining = workSeconds;
    running = false;
    finished = false;
    notifyListeners();
  }

  /// Recalcula el tiempo restante usando el reloj real del sistema.
  ///
  /// Se llama al volver a la pantalla de intervalos o al volver de background,
  /// para corregir desvíos si el `Timer.periodic` fue pausado por el OS.
  void syncFromWallClock() {
    if (!running || _phaseEndTime == null) return;
    final now = DateTime.now();
    final diff = _phaseEndTime!.difference(now).inSeconds;

    if (diff <= 0) {
      // La fase ya debió terminar; avanzar fases hasta alcanzar el presente.
      while (diff <= 0 && running) {
        _advancePhase();
      }
      notifyListeners();
    } else {
      remaining = diff;
      notifyListeners();
    }
  }

  void _advancePhase() {
    if (isWork) {
      isWork = false;
      remaining = restSeconds;
      _phaseEndTime = DateTime.now().add(Duration(seconds: restSeconds));
      _scheduleUtilityNotification();
    } else if (currentRound < rounds) {
      currentRound++;
      isWork = true;
      remaining = workSeconds;
      _phaseEndTime = DateTime.now().add(Duration(seconds: workSeconds));
      _scheduleUtilityNotification();
    } else {
      _timer?.cancel();
      _timer = null;
      running = false;
      finished = true;
      remaining = 0;
      _phaseEndTime = null;
    }
  }

  void _scheduleUtilityNotification() {
    if (finished || remaining <= 0) return;
    AlarmService.instance.setUtilityNotification(
      durationSeconds: remaining,
      title: _notificationTitle,
      body: _notificationBody,
    );
  }
}
