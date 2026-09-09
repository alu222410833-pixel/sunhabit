import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/services/storage_service.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

class HabitTimerSession {
  final String habitId;
  final String habitTitle;
  final int targetSeconds;
  DateTime _startedAt;
  int _accumulatedSeconds;
  bool _isPaused;

  HabitTimerSession({
    required this.habitId,
    required this.habitTitle,
    required this.targetSeconds,
    required this._startedAt,
    this._accumulatedSeconds = 0,
    this._isPaused = false,
  });

  bool get isPaused => _isPaused;
  bool get isRunning => !_isPaused;

  int get elapsedSeconds {
    if (_isPaused) return _accumulatedSeconds;
    final diff = DateTime.now().difference(_startedAt).inSeconds;
    return _accumulatedSeconds + (diff >= 0 ? diff : 0);
  }

  double get progress {
    if (targetSeconds <= 0) return 0.0;
    return (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);
  }

  void pause() {
    if (_isPaused) return;
    _accumulatedSeconds = elapsedSeconds;
    _isPaused = true;
  }

  void resume() {
    if (!_isPaused) return;
    _startedAt = DateTime.now();
    _isPaused = false;
  }

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'habitTitle': habitTitle,
        'targetSeconds': targetSeconds,
        'startedAt': _startedAt.toIso8601String(),
        'accumulatedSeconds': _accumulatedSeconds,
        'isPaused': _isPaused,
      };

  factory HabitTimerSession.fromJson(Map<String, dynamic> json) {
    return HabitTimerSession(
      habitId: json['habitId'] as String,
      habitTitle: json['habitTitle'] as String,
      targetSeconds: json['targetSeconds'] as int? ?? 0,
      startedAt: DateTime.parse(json['startedAt'] as String),
      accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
    );
  }
}

/// Servicio que gestiona la ejecución en segundo plano y tiempo real
/// de temporizadores y hábitos activos.
class HabitExecutionService extends ChangeNotifier {
  static final HabitExecutionService _instance =
      HabitExecutionService._internal();

  factory HabitExecutionService() => _instance;

  HabitExecutionService._internal();

  HabitTimerSession? _currentSession;
  Timer? _ticker;

  static const String _sessionKey = 'active_timer_session';

  final StorageService _storage = StorageService();

  bool _eyeCareEnabled = false;
  bool _eyeCareWorkPhase = true;
  int _eyeCareRemaining = 0;
  int? _eyeCareNotificationId;

  HabitTimerSession? get currentSession => _currentSession;

  bool isHabitActive(String habitId) =>
      _currentSession != null && _currentSession!.habitId == habitId;

  bool get eyeCareEnabled => _eyeCareEnabled;
  bool get eyeCareWorkPhase => _eyeCareWorkPhase;
  int get eyeCareRemaining => _eyeCareRemaining;

  void startTimer(Habit habit) {
    _startSession(habit);
    _eyeCareEnabled = false;
    _eyeCareWorkPhase = true;
    _eyeCareRemaining = 0;
    _cancelEyeCareNotification();
    notifyListeners();
  }

  void startTimerWithEyeCare(Habit habit) {
    _startSession(habit);
    _eyeCareEnabled = true;
    _eyeCareWorkPhase = true;
    _eyeCareRemaining = AppConstants.eyeCareWorkSeconds;
    _syncEyeCareNotification();
    notifyListeners();
  }

  void _startSession(Habit habit) {
    final target = habit.estimatedDuration?.inSeconds ?? 0;
    _currentSession = HabitTimerSession(
      habitId: habit.id,
      habitTitle: habit.title,
      targetSeconds: target,
      startedAt: DateTime.now(),
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _syncNotification();
    _persistSession();
  }

  void pauseTimer() {
    if (_currentSession == null) return;
    _currentSession!.pause();
    _cancelEyeCareNotification();
    _syncNotification();
    _persistSession();
    notifyListeners();
  }

  void resumeTimer() {
    if (_currentSession == null) return;
    _currentSession!.resume();
    _syncEyeCareNotification();
    _syncNotification();
    _persistSession();
    notifyListeners();
  }

  void toggleTimer() {
    if (_currentSession == null) return;
    if (_currentSession!.isPaused) {
      resumeTimer();
    } else {
      pauseTimer();
    }
  }

  void stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    _currentSession = null;
    _eyeCareEnabled = false;
    _eyeCareWorkPhase = true;
    _eyeCareRemaining = 0;
    _cancelEyeCareNotification();
    NotificationService.cancelTimerNotification();
    _clearPersistedSession();
    notifyListeners();
  }

  void finishTimer() {
    final session = _currentSession;
    final habitId = session?.habitId;
    final seconds = session?.elapsedSeconds ?? 0;
    stopTimer();
    if (habitId != null) {
      HabitsRepository().completeHabitWithDuration(habitId, seconds);
    }
  }

  /// Reanuda una sesión de temporizador persistida tras un reinicio de la app.
  /// Devuelve true si se restauró una sesión activa.
  Future<bool> restoreSession() async {
    final stored = await _storage.getString(_sessionKey);
    if (stored == null) return false;

    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      final session = HabitTimerSession.fromJson(json);
      // Si el hábito asociado ya no existe, descartamos la sesión.
      if (HabitsRepository().getHabitById(session.habitId) == null) {
        await _clearPersistedSession();
        return false;
      }
      _currentSession = session;
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      _syncNotification();
      notifyListeners();
      return true;
    } catch (_) {
      await _clearPersistedSession();
      return false;
    }
  }

  Future<void> _persistSession() async {
    if (_currentSession == null) return;
    try {
      await _storage.setString(
        _sessionKey,
        jsonEncode(_currentSession!.toJson()),
      );
    } catch (_) {
      // StorageService puede no estar inicializado en tests; ignoramos.
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      await _storage.remove(_sessionKey);
    } catch (_) {
      // StorageService puede no estar inicializado en tests; ignoramos.
    }
  }

  void _onTick() {
    if (_currentSession == null) return;

    if (_eyeCareEnabled && !_currentSession!.isPaused) {
      _eyeCareRemaining--;
      if (_eyeCareRemaining <= 0) {
        if (_eyeCareWorkPhase) {
          _eyeCareWorkPhase = false;
          _eyeCareRemaining = AppConstants.eyeCareBreakSeconds;
        } else {
          _eyeCareWorkPhase = true;
          _eyeCareRemaining = AppConstants.eyeCareWorkSeconds;
        }
        _syncEyeCareNotification();
      }
    }

    notifyListeners();

    final total = _currentSession!.targetSeconds;
    final elapsed = _currentSession!.elapsedSeconds;
    if (total > 0 && elapsed >= total && !_currentSession!.isPaused) {
      finishTimer();
    }
  }

  void _syncNotification() {
    if (_currentSession == null) return;
    NotificationService.showTimerNotification(
      elapsedSeconds: _currentSession!.elapsedSeconds,
      totalSeconds: _currentSession!.targetSeconds,
      title: _currentSession!.habitTitle,
      habitId: _currentSession!.habitId,
      isPaused: _currentSession!.isPaused,
    );
  }

  /// Programa una notificación nativa para el final de la fase actual de
  /// cuidado visual.
  ///
  /// Usa [AlarmService] para que el aviso suene aunque la app esté cerrada o
  /// el dispositivo tenga optimización agresiva de batería.
  void _syncEyeCareNotification() {
    if (!_eyeCareEnabled || _currentSession == null) return;
    _eyeCareNotificationId = AlarmService.instance.setUtilityNotification(
      durationSeconds: _eyeCareRemaining,
      title: _eyeCareTitle,
      body: _eyeCareBody,
    );
  }

  /// Cancela la notificación de cuidado visual programada.
  void _cancelEyeCareNotification() {
    final id = _eyeCareNotificationId;
    if (id != null) {
      AlarmService.instance.cancelUtilityNotificationById(id);
      _eyeCareNotificationId = null;
    }
  }

  String get _eyeCareTitle =>
      _eyeCareWorkPhase ? 'Hora de descansar la vista' : 'Descanso terminado';

  String get _eyeCareBody => _eyeCareWorkPhase
      ? 'Mira un objeto a 6 metros y parpadea suavemente.'
      : 'Ya puedes volver a mirar la pantalla.';
}
