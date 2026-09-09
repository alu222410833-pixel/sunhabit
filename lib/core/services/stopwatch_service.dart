import 'package:flutter/foundation.dart';

/// Servicio singleton que mantiene el estado del cronómetro.
///
/// Al vivir fuera del widget, el cronómetro sigue corriendo aunque el usuario
/// navegue a otra pantalla. `Stopwatch` usa el reloj monótono del sistema, así
/// que el tiempo transcurrido es exacto incluso sin ticker activo.
class StopwatchService extends ChangeNotifier {
  StopwatchService._();
  static final StopwatchService instance = StopwatchService._();

  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> laps = [];

  Duration get elapsed => _stopwatch.elapsed;
  bool get isRunning => _stopwatch.isRunning;

  void toggle() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    } else {
      _stopwatch.start();
    }
    notifyListeners();
  }

  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    laps.clear();
    notifyListeners();
  }

  void addLap() {
    if (elapsed == Duration.zero) return;
    laps.insert(0, elapsed);
    notifyListeners();
  }
}
