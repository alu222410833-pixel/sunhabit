import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/audio_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class AudioTrimResult {
  final int startSeconds;
  final int durationSeconds;

  const AudioTrimResult({
    required this.startSeconds,
    required this.durationSeconds,
  });
}

class AudioTrimDialog extends StatefulWidget {
  final String soundPath;
  final int? initialStartSeconds;
  final int? initialDurationSeconds;

  const AudioTrimDialog({
    super.key,
    required this.soundPath,
    this.initialStartSeconds,
    this.initialDurationSeconds,
  });

  static Future<AudioTrimResult?> show(
    BuildContext context, {
    required String soundPath,
    int? initialStartSeconds,
    int? initialDurationSeconds,
  }) {
    return showDialog<AudioTrimResult>(
      context: context,
      builder: (context) => AudioTrimDialog(
        soundPath: soundPath,
        initialStartSeconds: initialStartSeconds,
        initialDurationSeconds: initialDurationSeconds,
      ),
    );
  }

  @override
  State<AudioTrimDialog> createState() => _AudioTrimDialogState();
}

class _AudioTrimDialogState extends State<AudioTrimDialog> {
  late int _startSeconds;
  late int _durationSeconds;
  final AudioService _audio = AudioService();
  bool _isLoading = false;

  static const List<int> _presetDurations = [15, 30, 45, 60];
  /// Máximo por defecto para el slider cuando la duración real del archivo
  /// aún no se ha resuelto (o la carga falló).
  static const int _fallbackMaxStart = 240;

  @override
  void initState() {
    super.initState();
    _startSeconds = widget.initialStartSeconds ?? 0;
    _durationSeconds = widget.initialDurationSeconds ?? 30;
    _audio.addListener(_onAudioChanged);
    _loadAudio();
  }

  /// Reacciona a cambios en el `AudioService` (incluida la duración real del
  /// archivo cuando se resuelve) restringiendo el fragmento configurado para
  /// que nunca exceda el audio.
  void _onAudioChanged() {
    if (!mounted) return;
    final media = _audio.mediaDurationSeconds;
    if (media <= 0) return;
    final maxStart = (media - _durationSeconds).clamp(0, media);
    final needsClamp =
        _durationSeconds > media || _startSeconds > maxStart;
    if (needsClamp) {
      setState(_clampToMediaDuration);
    }
  }

  Future<void> _loadAudio() async {
    setState(() => _isLoading = true);
    try {
      await _audio.loadFile(widget.soundPath);
    } catch (_) {
      // Si falla la carga, el preview simplemente no reproducirá.
    }
    if (mounted) {
      _clampToMediaDuration();
      setState(() => _isLoading = false);
    }
  }

  /// Ajusta `_startSeconds` y `_durationSeconds` para que el fragmento
  /// configurado no exceda la duración real del archivo cuando esta ya se
  /// conoce. Si la duración es 0 (desconocida) no hace nada, para preservar
  /// el comportamiento de fallback.
  void _clampToMediaDuration() {
    final media = _audio.mediaDurationSeconds;
    if (media <= 0) return;

    // Asegurar que la duración seleccionada no exceda el audio.
    if (_durationSeconds > media) {
      _durationSeconds = media;
    }

    // Asegurar que el inicio + duración no exceda el audio.
    final maxStart = (media - _durationSeconds).clamp(0, media);
    if (_startSeconds > maxStart) {
      _startSeconds = maxStart;
    }
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioChanged);
    _audio.stop();
    _audio.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _fileName => widget.soundPath.split(RegExp(r'[/\\]')).last;

  void _togglePreview() {
    if (_audio.isPlaying) {
      _audio.stop();
    } else {
      _audio.playFragment(
        startSeconds: _startSeconds,
        durationSeconds: _durationSeconds,
        loop: true,
      );
    }
  }

  void _save() {
    _audio.stop();
    Navigator.of(context).pop(
      AudioTrimResult(
        startSeconds: _startSeconds,
        durationSeconds: _durationSeconds,
      ),
    );
  }

  /// Duraciones de preset disponibles según la duración real del audio.
  ///
  /// Si la duración real aún no se conoce (`mediaDurationSeconds == 0`) se
  /// ofrecen todos los presets como fallback. Si el audio es más corto que
  /// el preset más pequeño, se ofrece la duración real como única opción.
  List<int> get _availablePresets {
    final media = _audio.mediaDurationSeconds;
    if (media <= 0) return _presetDurations;
    final fitting = _presetDurations.where((p) => p <= media).toList();
    if (fitting.isEmpty) {
      // El audio es más corto que 15s: ofrecer su duración real completa.
      return [media];
    }
    return fitting;
  }

  /// Máximo valor permitido para el slider de inicio, basado en la duración
  /// real del audio y la duración del fragmento seleccionada.
  int get _maxStartSeconds {
    final media = _audio.mediaDurationSeconds;
    if (media <= 0) return _fallbackMaxStart;
    return (media - _durationSeconds).clamp(0, media);
  }

  /// Indica si la configuración actual es válida frente a la duración real.
  bool get _isConfigurationValid {
    final media = _audio.mediaDurationSeconds;
    if (media <= 0) return true; // Sin info, no bloqueamos al usuario.
    return _startSeconds + _durationSeconds <= media;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final endSeconds = _startSeconds + _durationSeconds;
    final media = _audio.mediaDurationSeconds;
    final maxStart = _maxStartSeconds;
    final availablePresets = _availablePresets;
    final isValid = _isConfigurationValid;

    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      color: AppColors.neonGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recortar audio de alarma',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _fileName,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Segment timeline visualizer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punto de inicio',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _formatTime(_startSeconds),
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.neonGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Text(
                            'Duración: ${_durationSeconds}s',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Punto final',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              _formatTime(endSeconds),
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Visual track con progreso real de reproducción
                    ListenableBuilder(
                      listenable: _audio,
                      builder: (context, _) {
                        final progress = _audio.durationSeconds > 0
                            ? (_audio.elapsedSeconds / _audio.durationSeconds)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(
                                height: 12,
                                color: AppColors.surfaceElevated,
                              ),
                              if (_audio.isPlaying)
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 12,
                                    color: AppColors.neonGreen,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Start time slider
              Text(
                'Ajustar inicio (${_formatTime(_startSeconds)})'
                '${media > 0 ? " / ${_formatTime(media)}" : ""}',
                style: textTheme.titleSmall,
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.neonGreen,
                  inactiveTrackColor: AppColors.surfaceHighest,
                  thumbColor: AppColors.neonGreen,
                  overlayColor: AppColors.neonGreen.withValues(alpha: 0.2),
                ),
                child: maxStart <= 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          media > 0
                              ? 'El audio es más corto que la duración '
                                  'seleccionada (${_durationSeconds}s).'
                              : 'Esperando duración del audio…',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Slider(
                        value: _startSeconds.toDouble().clamp(0, maxStart).toDouble(),
                        min: 0,
                        max: maxStart.toDouble(),
                        divisions: maxStart > 0 ? maxStart : 1,
                        label: _formatTime(_startSeconds),
                        onChanged: (val) {
                          _audio.stop();
                          setState(() => _startSeconds = val.toInt());
                        },
                      ),
              ),
              const SizedBox(height: 12),
              // Preset duration chips
              Text(
                'Duración del fragmento'
                '${media > 0 ? " (audio: ${_formatTime(media)})" : ""}',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: availablePresets.map((sec) {
                  final isSelected = _durationSeconds == sec;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          _audio.stop();
                          setState(() {
                            _durationSeconds = sec;
                            // Re-clamp start por si el nuevo fragmento no cabe.
                            final maxStartAfter =
                                (media - sec).clamp(0, media > 0 ? media : sec);
                            if (media > 0 &&
                                _startSeconds > maxStartAfter) {
                              _startSeconds = maxStartAfter;
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.neonGreen
                                : AppColors.surfaceHighest,
                            borderRadius:
                                BorderRadius.circular(AppConstants.cardRadius),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.neonGreen
                                  : AppColors.borderDark,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${sec}s',
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF152000)
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Preview button con estado real de reproducción
              ListenableBuilder(
                listenable: _audio,
                builder: (context, _) {
                  final isPlaying = _audio.isPlaying;
                  final elapsed = _audio.elapsedSeconds;
                  return OutlinedButton.icon(
                    onPressed:
                        (_isLoading || !isValid) ? null : _togglePreview,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neonGreen,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.neonGreen,
                          ),
                    label: Text(
                      isPlaying
                          ? 'Detener ($elapsed/${_durationSeconds}s)'
                          : '▶ Probar fragmento (${_formatTime(_startSeconds)} → ${_formatTime(endSeconds)})',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _audio.stop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isValid ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: const Color(0xFF152000),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.cardRadius),
                        ),
                      ),
                      child: Text(
                        isValid
                            ? 'Guardar fragmento'
                            : 'Fragmento fuera de rango',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
