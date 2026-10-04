/// Tipo de recordatorio que puede tener un hábito.
class Reminder {
  final int hour;
  final int minute;
  final String type; // 'Notificación' o 'Alarma'
  final String? soundPath; // Ruta de audio para alarmas (opcional)
  final int? audioStartSeconds; // Segundo de inicio del recorte
  final int? audioDurationSeconds; // Duración en segundos del recorte (ej. 30s)
  /// Días de la semana en los que aplica el recordatorio (L..D).
  /// Si es null, aplica a todos los días en los que el hábito esté programado.
  final List<bool>? weekDays;

  const Reminder({
    required this.hour,
    required this.minute,
    this.type = 'Notificación',
    this.soundPath,
    this.audioStartSeconds,
    this.audioDurationSeconds,
    this.weekDays,
  });

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Devuelve el nombre de archivo de sonido limpio, sin los sufijos internos
  /// (`_extracted_<timestamp>`, `_trimmed_<timestamp>`) para mostrar en UI.
  String get soundFileName {
    if (soundPath == null || soundPath!.isEmpty) return '';
    final raw = soundPath!.split(RegExp(r'[/\\]')).last;
    return _cleanFileName(raw);
  }

  static String _cleanFileName(String name) => name
      .replaceAll(RegExp(r'_(extracted|trimmed)_\d{13,}(?=\.)'), '')
      .replaceAll(RegExp(r'_\d{13,}(?=\.)'), '');

  /// Texto descriptivo del fragmento de audio seleccionado, ej.
  /// `00:00 - 00:30 (30s)`, o `null` si no hay sonido configurado.
  String? get audioFragmentText {
    if (soundPath == null || soundPath!.isEmpty) return null;
    final start = audioStartSeconds ?? 0;
    final duration = audioDurationSeconds ?? 30;
    final end = start + duration;
    return '${_formatMMSS(start)} - ${_formatMMSS(end)} (${duration}s)';
  }

  static String _formatMMSS(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Reminder copyWith({
    int? hour,
    int? minute,
    String? type,
    String? soundPath,
    int? audioStartSeconds,
    int? audioDurationSeconds,
    List<bool>? weekDays,
  }) =>
      Reminder(
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        type: type ?? this.type,
        soundPath: soundPath ?? this.soundPath,
        audioStartSeconds: audioStartSeconds ?? this.audioStartSeconds,
        audioDurationSeconds:
            audioDurationSeconds ?? this.audioDurationSeconds,
        weekDays: weekDays ?? this.weekDays,
      );

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
        'type': type,
        'soundPath': soundPath,
        'audioStartSeconds': audioStartSeconds,
        'audioDurationSeconds': audioDurationSeconds,
        'weekDays': weekDays,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        type: json['type'] as String,
        soundPath: json['soundPath'] as String?,
        audioStartSeconds: json['audioStartSeconds'] as int?,
        audioDurationSeconds: json['audioDurationSeconds'] as int?,
        weekDays: (json['weekDays'] as List<dynamic>?)?.cast<bool>(),
      );
}
