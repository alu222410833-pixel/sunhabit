import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:sunhabit/core/services/alarm_service.dart';

/// Servicio singleton que mantiene el estado del temporizador de enfoque.
///
/// Al vivir fuera del widget, el timer sigue corriendo aunque el usuario
/// navegue a otra pantalla. Al volver, el estado se restaura automáticamente.
class FocusTimerService extends ChangeNotifier {
  FocusTimerService._();
  static final FocusTimerService instance = FocusTimerService._();

  int initialSeconds = 25 * 60;
  int remaining = 25 * 60;
  bool running = false;

  Timer? _timer;
  DateTime? _endTime;
  int? _notificationId;

  void setInput(int hours, int minutes, int seconds) {
    if (running) return;
    final total = hours * 3600 + minutes * 60 + seconds;
    initialSeconds = total;
    remaining = total;
    notifyListeners();
  }

  void toggle() {
    if (running) {
      pause();
      return;
    }
    if (remaining <= 0) remaining = initialSeconds;
    if (remaining <= 0) return;
    running = true;
    _endTime = DateTime.now().add(Duration(seconds: remaining));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _notificationId = AlarmService.instance.setUtilityNotification(
      durationSeconds: remaining,
      title: 'Temporizador',
      body: 'El temporizador ha terminado',
    );
    notifyListeners();
  }

  void _tick() {
    if (remaining > 1) {
      remaining--;
      notifyListeners();
    } else {
      remaining = 0;
      _timer?.cancel();
      _timer = null;
      running = false;
      _endTime = null;
      notifyListeners();
    }
  }

  void _cancelNotification() {
    if (_notificationId != null) {
      AlarmService.instance.cancelUtilityNotificationById(_notificationId!);
      _notificationId = null;
    }
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _cancelNotification();
    running = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _cancelNotification();
    running = false;
    remaining = initialSeconds;
    notifyListeners();
  }

  /// Recalcula el tiempo restante usando el reloj real del sistema.
  void syncFromWallClock() {
    if (!running || _endTime == null) return;
    final diff = _endTime!.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      remaining = 0;
      _timer?.cancel();
      _timer = null;
      running = false;
      _endTime = null;
    } else {
      remaining = diff;
    }
    notifyListeners();
  }
}
