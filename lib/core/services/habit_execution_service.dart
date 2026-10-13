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

  /// Día al que pertenece la sesión (cuando se inició por primera
  /// vez). Si un temporizador cruza medianoche, su cumplimiento se
  /// registra en este día, no en el de finalización.
  final DateTime logDay;

  HabitTimerSession({
    required this.habitId,
    required this.habitTitle,
    required this.targetSeconds,
    required this._startedAt,
    this._accumulatedSeconds = 0,
    this._isPaused = false,
    DateTime? logDay,
  }) : logDay = logDay ??
            DateTime(_startedAt.year, _startedAt.month, _startedAt.day);

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
        'logDay': logDay.toIso8601String(),
      };

  factory HabitTimerSession.fromJson(Map<String, dynamic> json) {
    return HabitTimerSession(
      habitId: json['habitId'] as String,
      habitTitle: json['habitTitle'] as String,
      targetSeconds: json['targetSeconds'] as int? ?? 0,
      startedAt: DateTime.parse(json['startedAt'] as String),
      accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      logDay: json['logDay'] != null
          ? DateTime.parse(json['logDay'] as String)
          : null,
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

  /// Segundos restantes "congelados" de la fase de cuidado visual.
  /// Se usa al pausar el timer y al persistir la sesión; mientras el
  /// timer corre, el tiempo real se deriva de [_eyeCarePhaseEndsAt]
  /// (reloj de pared — los ticks del Timer se suspenden en background
  /// y un contador por tick quedaba desincronizado del tiempo real).
  int _eyeCareRemaining = 0;

  /// Instante en que termina la fase actual de cuidado visual mientras
  /// el timer corre; null si está pausado o el cuidado visual apagado.
  DateTime? _eyeCarePhaseEndsAt;

  HabitTimerSession? get currentSession => _currentSession;

  bool isHabitActive(String habitId) =>
      _currentSession != null && _currentSession!.habitId == habitId;

  /// Re-muestra la notificación persistente del temporizador (y el
  /// aviso de cuidado visual pendiente) si hay una sesión activa.
  ///
  /// Se usa tras un `cancelAll()` global (p. ej. al importar un backup
  /// o en la migración de IDs), que también borra esta notificación.
  void resyncActiveNotification() {
    if (_currentSession == null) return;
    _syncNotification();
    _syncTimerEndNotification();
    if (_eyeCareEnabled && !_currentSession!.isPaused) {
      _syncEyeCareNotification();
    }
  }

  bool get eyeCareEnabled => _eyeCareEnabled;
  bool get eyeCareWorkPhase => _eyeCareWorkPhase;

  /// Segundos restantes de la fase actual de cuidado visual.
  /// Con el timer corriendo se calcula por reloj de pared; en pausa
  /// devuelve el valor congelado.
  int get eyeCareRemaining {
    if (!_eyeCareEnabled) return 0;
    final ends = _eyeCarePhaseEndsAt;
    if (ends == null) return _eyeCareRemaining;
    final rem = ends.difference(DateTime.now()).inSeconds;
    return rem > 0 ? rem : 0;
  }

  int get _eyeCarePhaseSeconds => _eyeCareWorkPhase
      ? AppConstants.eyeCareWorkSeconds
      : AppConstants.eyeCareBreakSeconds;

  void startTimer(Habit habit) {
    _eyeCareEnabled = false;
    _eyeCareWorkPhase = true;
    _eyeCareRemaining = 0;
    _eyeCarePhaseEndsAt = null;
    _cancelEyeCareNotification();
    _startSession(habit);
    notifyListeners();
  }

  void startTimerWithEyeCare(Habit habit) {
    _eyeCareEnabled = true;
    _eyeCareWorkPhase = true;
    _eyeCareRemaining = AppConstants.eyeCareWorkSeconds;
    _eyeCarePhaseEndsAt =
        DateTime.now().add(Duration(seconds: _eyeCareRemaining));
    _startSession(habit);
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
    _syncTimerEndNotification();
    _persistSession();
  }

  void pauseTimer() {
    if (_currentSession == null) return;
    _ticker?.cancel();
    _ticker = null;
    _currentSession!.pause();
    // Congelar el remanente de la fase de cuidado visual.
    _eyeCareRemaining = eyeCareRemaining;
    _eyeCarePhaseEndsAt = null;
    _cancelEyeCareNotification();
    _cancelTimerEndNotification();
    _syncNotification();
    _persistSession();
    notifyListeners();
  }

  void resumeTimer() {
    if (_currentSession == null) return;
    _currentSession!.resume();
    if (_eyeCareEnabled) {
      // Si la pausa ocurrió justo al final de una fase, el remanente
      // quedó en 0: avanzar a la siguiente antes de re-anclar.
      if (_eyeCareRemaining <= 0) {
        _eyeCareWorkPhase = !_eyeCareWorkPhase;
        _eyeCareRemaining = _eyeCarePhaseSeconds;
      }
      _eyeCarePhaseEndsAt =
          DateTime.now().add(Duration(seconds: _eyeCareRemaining));
      _syncEyeCareNotification();
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _syncTimerEndNotification();
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
    _eyeCarePhaseEndsAt = null;
    _cancelEyeCareNotification();
    _cancelTimerEndNotification();
    NotificationService.cancelTimerNotification();
    _clearPersistedSession();
    notifyListeners();
  }

  void finishTimer() {
    final session = _currentSession;
    final habitId = session?.habitId;
    final seconds = session?.elapsedSeconds ?? 0;
    final logDay = session?.logDay;
    stopTimer();
    if (habitId != null) {
      // El cumplimiento pertenece al día en que se inició la sesión:
      // un temporizador que cruza medianoche no debe registrar su
      // progreso en el día nuevo.
      HabitsRepository().completeHabitWithDuration(
        habitId,
        seconds,
        date: logDay,
      );
    }
  }

  /// Reanuda una sesión de temporizador persistida tras un reinicio de la app.
  /// Devuelve true si se restauró una sesión activa.
  Future<bool> restoreSession() async {
    // Una sesión viva en memoria es la fuente de verdad: rehidratarla
    // desde el disco pisaría su progreso (p. ej. si una acción de
    // notificación llega mientras la app corre).
    if (_currentSession != null) return true;
    final stored = await _storage.getString(_sessionKey);
    if (stored == null) return false;

    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      final session = HabitTimerSession.fromJson(json);
      // Si el hábito asociado ya no existe, descartamos la sesión.
      if (HabitsRepository().getHabitById(session.habitId) == null) {
        _cancelEyeCareNotification();
        await _clearPersistedSession();
        return false;
      }
      _currentSession = session;
      // Restaurar el estado de cuidado visual persistido con la sesión;
      // si no se restaura, el toggle queda apagado pero la notificación
      // nativa ya programada sonaría igual (huérfana).
      _eyeCareEnabled = json['eyeCareEnabled'] as bool? ?? false;
      _eyeCareWorkPhase = json['eyeCareWorkPhase'] as bool? ?? true;
      _eyeCareRemaining = json['eyeCareRemaining'] as int? ?? 0;
      // Re-anclar la fase al reloj de pared con el remanente guardado.
      _eyeCarePhaseEndsAt =
          (_eyeCareEnabled && !session.isPaused && _eyeCareRemaining > 0)
              ? DateTime.now().add(Duration(seconds: _eyeCareRemaining))
              : null;
      _ticker?.cancel();
      // En pausa no hace falta ticker: el tiempo está congelado.
      if (!session.isPaused) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      }
      _syncNotification();
      _syncTimerEndNotification();
      if (_eyeCareEnabled && !session.isPaused) {
        // Reprograma el aviso de la fase actual (reemplaza el pendiente
        // huérfano con el tiempo restante real).
        _syncEyeCareNotification();
      } else {
        _cancelEyeCareNotification();
      }
      notifyListeners();
      return true;
    } catch (_) {
      _cancelEyeCareNotification();
      await _clearPersistedSession();
      return false;
    }
  }

  Future<void> _persistSession() async {
    if (_currentSession == null) return;
    try {
      await _storage.setString(
        _sessionKey,
        jsonEncode(
          _currentSession!.toJson()
            ..['eyeCareEnabled'] = _eyeCareEnabled
            ..['eyeCareWorkPhase'] = _eyeCareWorkPhase
            ..['eyeCareRemaining'] = eyeCareRemaining,
        ),
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

  /// Al volver de background el `Timer.periodic` pudo quedar suspendido:
  /// recalcula de inmediato el estado (el tiempo transcurrido y las fases
  /// de cuidado visual son por reloj de pared, así que nada se pierde) y
  /// cierra la sesión si ya se alcanzó la meta — sin esperar al siguiente
  /// tick, que dejaría la UI mostrando un tiempo congelado ~1 segundo.
  void syncAfterResume() {
    if (_currentSession == null) return;
    _onTick();
  }

  void _onTick() {
    if (_currentSession == null) return;

    if (_eyeCareEnabled &&
        !_currentSession!.isPaused &&
        _eyeCarePhaseEndsAt != null) {
      var phaseChanged = false;
      // Avanzar por reloj de pared: si la app estuvo suspendida pueden
      // haber pasado varias fases completas entre tick y tick.
      while (eyeCareRemaining <= 0) {
        _eyeCareWorkPhase = !_eyeCareWorkPhase;
        _eyeCarePhaseEndsAt = _eyeCarePhaseEndsAt!
            .add(Duration(seconds: _eyeCarePhaseSeconds));
        phaseChanged = true;
      }
      if (phaseChanged) _syncEyeCareNotification();
      _eyeCareRemaining = eyeCareRemaining;
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
    AlarmService.instance.setUtilityNotification(
      id: AlarmService.habitEyeCareNotificationId,
      durationSeconds: _eyeCareRemaining,
      title: _eyeCareTitle,
      body: _eyeCareBody,
    );
  }

  /// Cancela la notificación de cuidado visual programada.
  void _cancelEyeCareNotification() {
    AlarmService.instance.cancelUtilityNotificationById(
      AlarmService.habitEyeCareNotificationId,
    );
  }

  /// Programa una notificación nativa para cuando el temporizador
  /// alcance su meta.
  ///
  /// Sin esto, si la app está suspendida o cerrada cuando el tiempo se
  /// cumple, el auto-cierre depende del ticker de Dart (suspendido) y
  /// el usuario vuelve a encontrar la sesión "sin avanzar". La notificación
  /// nativa suena puntual aunque la app esté muerta; al volver, el ticker
  /// (o [syncAfterResume]) cierra la sesión.
  void _syncTimerEndNotification() {
    final session = _currentSession;
    if (session == null || session.targetSeconds <= 0 || session.isPaused) {
      _cancelTimerEndNotification();
      return;
    }
    AlarmService.instance.setUtilityNotification(
      id: AlarmService.habitTimerEndNotificationId,
      durationSeconds: session.targetSeconds - session.elapsedSeconds,
      title: session.habitTitle,
      body: '¡Tiempo completado!',
    );
  }

  void _cancelTimerEndNotification() {
    AlarmService.instance.cancelUtilityNotificationById(
      AlarmService.habitTimerEndNotificationId,
    );
  }

  String get _eyeCareTitle =>
      _eyeCareWorkPhase ? 'Hora de descansar la vista' : 'Descanso terminado';

  String get _eyeCareBody => _eyeCareWorkPhase
      ? 'Mira un objeto a 6 metros y parpadea suavemente.'
      : 'Ya puedes volver a mirar la pantalla.';
}
