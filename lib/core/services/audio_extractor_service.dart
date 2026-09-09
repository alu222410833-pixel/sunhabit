import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Extrae la pista de audio de archivos de video/audio y la recorta para usar
/// como tono de alarma en SunHabit.
///
/// El flujo garantiza compatibilidad con el reproductor nativo de Android
/// (`MediaPlayer`) que usa el paquete `alarm`:
/// - Salida en MP3 (codec LAME) a 192 kbps, estéreo, 44.1 kHz.
/// - Validación post-proceso: el archivo existe, tiene contenido y FFmpeg es
///   capaz de leer su duración.
/// - Limpieza de archivos parciales si el comando falla.
/// - Comandos robustos que ubican `-t` como opción de salida para evitar
///   recortes erráticos.
class AudioExtractorService {
  /// Extensiones de video reconocidas para decidir si un archivo picked debe
  /// pasar por extracción en lugar de usarse directamente como audio.
  static const videoExtensions = [
    '.mp4', '.mov', '.mkv', '.avi', '.webm', '.3gp', '.flv', '.m4v', '.wmv',
    '.mpg', '.mpeg', '.ts', '.m2ts',
  ];

  /// Extensiones de audio reconocidas. Si el usuario elige uno de estos, no
  /// hace falta re-encodificar; se copia directamente al directorio persistente.
  static const audioExtensions = [
    '.mp3', '.m4a', '.aac', '.ogg', '.wav', '.flac', '.wma', '.opus',
  ];

  /// Devuelve `true` si [filePath] apunta a un archivo de video por su extensión.
  static bool isVideoFile(String filePath) {
    final lower = filePath.toLowerCase();
    return videoExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Devuelve `true` si [filePath] ya es un archivo de audio nativo.
  static bool isAudioFile(String filePath) {
    final lower = filePath.toLowerCase();
    return audioExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Devuelve el directorio persistente donde se guardan los audios extraídos.
  static Future<Directory> get _outputDir async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/extracted_audio');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    return outDir;
  }

  /// Extrae el nombre base sin extensión de una ruta de archivo.
  static String _basenameWithoutExtension(String filePath) {
    final parts = filePath.split(RegExp(r'[/\\]'));
    final name = parts.isEmpty ? filePath : parts.last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) return name;
    return name.substring(0, dotIndex);
  }

  /// Extrae la extensión (incluyendo el punto) de una ruta de archivo.
  static String _extension(String filePath) {
    final parts = filePath.split(RegExp(r'[/\\]'));
    final name = parts.isEmpty ? filePath : parts.last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex).toLowerCase();
  }

  /// Construye una ruta de salida única dentro del directorio persistente.
  static Future<String> _outputPath(String inputPath, String suffix) async {
    final outDir = await _outputDir;
    final baseName = _basenameWithoutExtension(inputPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${outDir.path}/${baseName}_$suffix$timestamp.mp3';
  }

  /// Extrae el audio de [videoPath] y devuelve la ruta del `.mp3` resultante,
  /// o `null` si la extracción falló.
  ///
  /// [onProgress] (0.0–1.0) se invoca con el progreso de la sesión FFmpeg.
  /// Actualmente solo se invoca al finalizar porque FFmpegKit no reporta
  /// progreso fino de forma síncrona con todos los comandos.
  Future<String?> extractAudio(
    String videoPath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final inputFile = File(videoPath);
      if (!inputFile.existsSync()) {
        debugPrint(
            '[AudioExtractorService] Archivo de entrada no existe: $videoPath');
        return null;
      }

      final outputPath = await _outputPath(videoPath, 'extracted_');

      // Re-encode a MP3 estándar para máxima compatibilidad con MediaPlayer
      // nativo de Android y el paquete `alarm`.
      final command =
          '-y -i "${inputFile.path}" -vn -c:a libmp3lame -b:a 192k '
          '-ac 2 -ar 44100 -id3v2_version 3 "$outputPath"';

      debugPrint('[AudioExtractorService] Executing: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      final logs = await session.getLogsAsString();

      onProgress?.call(1.0);

      if (ReturnCode.isSuccess(returnCode) &&
          await _validateOutput(outputPath)) {
        debugPrint('[AudioExtractorService] Éxito: $outputPath');
        return outputPath;
      }

      debugPrint(
          '[AudioExtractorService] MP3 falló, intentando AAC fallback...');
      debugPrint('[AudioExtractorService] FFmpeg output: $output\n$logs');

      // Fallback a AAC en contenedor M4A si LAME no estuviese disponible.
      final fallbackM4a = outputPath.replaceAll('.mp3', '.m4a');
      final fallbackCommand =
          '-y -i "${inputFile.path}" -vn -c:a aac -b:a 192k -ac 2 -ar 44100 '
          '-movflags +faststart "$fallbackM4a"';

      final fallbackSession = await FFmpegKit.execute(fallbackCommand);
      final fallbackReturn = await fallbackSession.getReturnCode();

      if (ReturnCode.isSuccess(fallbackReturn) &&
          await _validateOutput(fallbackM4a)) {
        debugPrint(
            '[AudioExtractorService] Fallback AAC exitoso: $fallbackM4a');
        return fallbackM4a;
      }

      debugPrint(
          '[AudioExtractorService] Extracción fallida también con AAC.');
      _deleteIfExists(outputPath);
      _deleteIfExists(fallbackM4a);
      return null;
    } catch (e, st) {
      debugPrint('[AudioExtractorService] Error inesperado: $e\n$st');
      return null;
    }
  }

  /// Si [inputPath] es un audio ya válido (MP3, M4A, etc.) y no es un video,
  /// lo copia al directorio persistente sin re-encodificar para preservar
  /// calidad y velocidad. Devuelve `null` si no es audio o la copia falla.
  ///
  /// Útil cuando el usuario elige directamente un archivo de audio existente.
  Future<String?> copyAudioToPersistentStorage(String inputPath) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync()) return null;
      if (isVideoFile(inputPath)) return null;

      final ext = _extension(inputPath);
      final outDir = await _outputDir;
      final baseName = _basenameWithoutExtension(inputPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${outDir.path}/${baseName}_$timestamp$ext';

      await inputFile.copy(outputPath);
      if (await _validateOutput(outputPath)) {
        return outputPath;
      }
      _deleteIfExists(outputPath);
      return null;
    } catch (e, st) {
      debugPrint('[AudioExtractorService] Error copiando audio: $e\n$st');
      return null;
    }
  }

  /// Recorta un archivo de audio a un nuevo archivo persistente con los
  /// segundos de inicio y duración configurados.
  ///
  /// Si [startSeconds] es 0 y [durationSeconds] es 0 (o negativo) devuelve el
  /// [inputPath] original sin crear un nuevo archivo.
  ///
  /// El comando utiliza `-ss` antes del input (búsqueda rápida) y `-t` después
  /// del input para limitar la duración de salida. Esto evita que el recorte
  /// genere archivos corruptos o con duración incorrecta.
  Future<String?> trimAudio(
    String inputPath, {
    required int startSeconds,
    required int durationSeconds,
  }) async {
    if (startSeconds <= 0 && durationSeconds <= 0) return inputPath;

    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      debugPrint(
          '[AudioExtractorService] Archivo a recortar no existe: $inputPath');
      return inputPath;
    }

    try {
      final outputPath = await _outputPath(inputPath, 'trimmed_');

      // Usamos `-ss` antes de `-i` para seeking rápido y `-t` después de `-i`
      // para definir la duración de salida del fragmento.
      final command =
          '-y -ss $startSeconds -i "${inputFile.path}" -t $durationSeconds '
          '-c:a libmp3lame -b:a 192k -ac 2 -ar 44100 -id3v2_version 3 '
          '"$outputPath"';

      debugPrint('[AudioExtractorService] Trim command: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      final logs = await session.getLogsAsString();

      if (ReturnCode.isSuccess(returnCode) &&
          await _validateOutput(outputPath)) {
        debugPrint('[AudioExtractorService] Trim exitoso: $outputPath');
        return outputPath;
      }

      debugPrint('[AudioExtractorService] Trim MP3 falló, intentando AAC...');
      debugPrint('[AudioExtractorService] FFmpeg output: $output\n$logs');

      final fallbackM4a = outputPath.replaceAll('.mp3', '.m4a');
      final fallbackCommand =
          '-y -ss $startSeconds -i "${inputFile.path}" -t $durationSeconds '
          '-c:a aac -b:a 192k -ac 2 -ar 44100 -movflags +faststart '
          '"$fallbackM4a"';

      final fallbackSession = await FFmpegKit.execute(fallbackCommand);
      final fallbackReturn = await fallbackSession.getReturnCode();

      if (ReturnCode.isSuccess(fallbackReturn) &&
          await _validateOutput(fallbackM4a)) {
        return fallbackM4a;
      }

      // Si todo falla, devolvemos el original para no dejar al usuario sin
      // sonido, aunque el recorte no se aplique.
      _deleteIfExists(outputPath);
      _deleteIfExists(fallbackM4a);
      return inputPath;
    } catch (e, st) {
      debugPrint('[AudioExtractorService] Error recortando: $e\n$st');
      return inputPath;
    }
  }

  /// Valida que [filePath] exista, tenga tamaño > 0 y que FFmpeg sea capaz de
  /// leer su duración. Si es válido, devuelve `true`.
  static Future<bool> _validateOutput(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      if (file.lengthSync() <= 0) return false;

      // Sonda FFmpeg para confirmar que el archivo es un audio válido.
      // FFmpeg `-i file` sin salida devuelve 1 incluso para archivos válidos,
      // por eso analizamos el texto de salida en lugar del return code.
      final probeCommand = '-i "$filePath"';
      final session = await FFmpegKit.execute(probeCommand);
      final output = await session.getOutput();
      final logs = await session.getLogsAsString();
      final combined = '$output\n$logs';

      // FFmpeg indica error de lectura con frases claras.
      if (combined.contains('Invalid data found') ||
          combined.contains('could not find codec parameters') ||
          combined.contains('No such file')) {
        return false;
      }

      // Un archivo válido debe reportar duración.
      if (!combined.contains('Duration:')) {
        return false;
      }

      return true;
    } catch (e, st) {
      debugPrint('[AudioExtractorService] Error validando $filePath: $e\n$st');
      return false;
    }
  }

  /// Devuelve la duración en segundos de un archivo de audio usando FFmpeg,
  /// o `null` si no se puede determinar.
  static Future<int?> probeDurationSeconds(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync() || file.lengthSync() <= 0) return null;

      final command = '-i "$filePath" -f null -';
      final session = await FFmpegKit.execute(command);
      final output = await session.getOutput();
      final logs = await session.getLogsAsString();
      final combined = '$output\n$logs';

      final regex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})');
      final match = regex.firstMatch(combined);
      if (match == null) return null;

      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = double.parse(match.group(3)!);
      return (hours * 3600 + minutes * 60 + seconds).round();
    } catch (e, st) {
      debugPrint('[AudioExtractorService] Error probando duración: $e\n$st');
      return null;
    }
  }

  static void _deleteIfExists(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
