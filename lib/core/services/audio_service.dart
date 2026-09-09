import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Servicio de reproducción de audio para previsualizar fragmentos de alarma.
///
/// Usa [just_audio] para reproducir un archivo local desde un punto de inicio
/// [startSeconds] durante una duración [durationSeconds], deteniéndose
/// automáticamente al alcanzar el final del fragmento.
///
/// Cada instancia mantiene su propio [AudioPlayer] y suscripciones, por lo que
/// no debe compartirse entre consumidores simultáneos: crea una instancia por
/// consumidor (por ejemplo, una por diálogo) y llama [dispose] al destruirlo.
class AudioService extends ChangeNotifier {
  AudioService();

  final AudioPlayer _player = AudioPlayer();

  /// Posición actual de reproducción dentro del fragmento (en segundos).
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  /// Duración total del fragmento configurado (en segundos).
  int _durationSeconds = 0;
  int get durationSeconds => _durationSeconds;

  /// Duración real del archivo de audio cargado (en segundos).
  ///
  /// Es `0` mientras el reproductor no haya resuelto la duración del archivo
  /// (por ejemplo, durante la carga o si la carga falló).
  int _mediaDurationSeconds = 0;
  int get mediaDurationSeconds => _mediaDurationSeconds;

  /// Indica si hay un fragmento reproduciéndose.
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration?>? _durationSub;

  /// Carga un archivo de audio local y prepara el reproductor.
  ///
  /// Suscribe a [AudioPlayer.durationStream] para mantener actualizado
  /// [mediaDurationSeconds] con la duración real del archivo cargado.
  Future<void> loadFile(String path) async {
    _durationSub?.cancel();
    _mediaDurationSeconds = 0;
    await _player.setFilePath(path);

    // Algunas plataformas exponen la duración de forma sincrónica tras la
    // carga; si está disponible la usamos como valor inicial.
    final syncDuration = _player.duration;
    if (syncDuration != null && syncDuration.inSeconds > 0) {
      _mediaDurationSeconds = syncDuration.inSeconds;
      notifyListeners();
    }

    _durationSub = _player.durationStream.listen((duration) {
      final newSeconds = duration?.inSeconds ?? 0;
      if (newSeconds != _mediaDurationSeconds) {
        _mediaDurationSeconds = newSeconds;
        notifyListeners();
      }
    });
  }

  /// Reproduce un fragmento del audio cargado.
  ///
  /// [startSeconds] — segundo de inicio del fragmento.
  /// [durationSeconds] — duración del fragmento a reproducir.
  /// [loop] — si es `true`, el fragmento se repite en bucle.
  Future<void> playFragment({
    required int startSeconds,
    required int durationSeconds,
    bool loop = false,
  }) async {
    _durationSeconds = durationSeconds;
    _elapsedSeconds = 0;
    _isPlaying = true;
    notifyListeners();

    final startPosition = Duration(seconds: startSeconds);
    final endPosition = Duration(seconds: startSeconds + durationSeconds);

    await _player.seek(startPosition);
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await _player.play();

    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((position) {
      final elapsed = position.inSeconds - startSeconds;
      _elapsedSeconds = elapsed.clamp(0, durationSeconds);
      notifyListeners();

      // Detener automáticamente al alcanzar el final del fragmento.
      if (!loop && position >= endPosition) {
        stop();
      }
    });

    _stateSub?.cancel();
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && !loop) {
        stop();
      }
    });
  }

  /// Pausa la reproducción del fragmento.
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// Detiene la reproducción y reinicia el estado.
  ///
  /// No cancela la suscripción a [AudioPlayer.durationStream] para conservar
  /// [mediaDurationSeconds] disponible entre previsualizaciones del mismo
  /// archivo. Usa [unload] para liberar también esa suscripción.
  Future<void> stop() async {
    await _player.stop();
    _positionSub?.cancel();
    _positionSub = null;
    _stateSub?.cancel();
    _stateSub = null;
    _isPlaying = false;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  /// Libera la suscripción de duración y reinicia [mediaDurationSeconds].
  ///
  /// Útil cuando se descarta el servicio o se va a cargar otro archivo sin
  /// pasar por [loadFile] (que ya gestiona la suscripción internamente).
  void unload() {
    _durationSub?.cancel();
    _durationSub = null;
    _mediaDurationSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
