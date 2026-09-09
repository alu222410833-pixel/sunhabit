import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Extrae la pista de audio de un archivo de video y la guarda como `.m4a`
/// (AAC) en el directorio de documentos de la app.
///
/// Usa FFmpegKit (variante `ffmpeg_kit_flutter_new_audio`) con el comando
/// `-i <video> -vn -c:a aac -b:a 192k <salida>.m4a`, que descarta el vídeo y
/// re-codifica el audio a AAC para máxima compatibilidad con el paquete
/// `alarm` y `just_audio`.
///
/// El archivo resultante se persiste en
/// `getApplicationDocumentsDirectory()/extracted_audio/` para que no lo borre
/// el sistema (igual que las imágenes, ver AGENTS.md 2026-09-08).
class AudioExtractorService {
  /// Extensiones de video reconocidas para decidir si un archivo picked debe
  /// pasar por extracción en lugar de usarse directamente como audio.
  static const videoExtensions = [
    '.mp4', '.mov', '.mkv', '.avi', '.webm', '.3gp', '.flv', '.m4v', '.wmv',
    '.mpg', '.mpeg', '.ts', '.m2ts',
  ];

  /// Devuelve `true` si [path] apunta a un archivo de video por su extensión.
  static bool isVideoFile(String path) {
    final lower = path.toLowerCase();
    return videoExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Extrae el audio de [videoPath] y devuelve la ruta del `.mp3` resultante,
  /// o `null` si la extracción falló.
  ///
  /// [onProgress] (0.0–1.0) se invoca con el progreso de la sesión FFmpeg,
  /// útil para mostrar un indicador mientras se procesa.
  Future<String?> extractAudio(
    String videoPath, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/extracted_audio');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    final baseName = videoPath
        .split(RegExp(r'[/\\]'))
        .last
        .split('.')
        .first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${outDir.path}/${baseName}_$timestamp.mp3';

    // Se codifica a MP3 para máxima compatibilidad con el MediaPlayer de
    // Android y el paquete alarm.
    final command = '-y -i "$videoPath" -vn -c:a libmp3lame -b:a 192k "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (onProgress != null) {
      onProgress(1.0);
    }

    if (ReturnCode.isSuccess(returnCode)) {
      final file = File(outputPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return outputPath;
      }
    }

    // Fallback con AAC si libmp3lame no estuviese disponible
    final fallbackM4a = '${outDir.path}/${baseName}_$timestamp.m4a';
    final fallbackCommand = '-y -i "$videoPath" -vn -c:a aac -b:a 192k -movflags +faststart "$fallbackM4a"';
    final fallbackSession = await FFmpegKit.execute(fallbackCommand);
    final fallbackReturn = await fallbackSession.getReturnCode();

    if (ReturnCode.isSuccess(fallbackReturn)) {
      final file = File(fallbackM4a);
      if (file.existsSync() && file.lengthSync() > 0) {
        return fallbackM4a;
      }
    }

    // Limpieza del archivo parcial si la extracción falló.
    final partial = File(outputPath);
    if (partial.existsSync()) partial.deleteSync();
    final partialM4a = File(fallbackM4a);
    if (partialM4a.existsSync()) partialM4a.deleteSync();
    return null;
  }

  /// Recorta un archivo de audio o extraído a un nuevo archivo persistente con los
  /// segundos de inicio y duración configurados.
  Future<String?> trimAudio(
    String inputPath, {
    required int startSeconds,
    required int durationSeconds,
  }) async {
    if (startSeconds <= 0 && durationSeconds <= 0) return inputPath;

    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/extracted_audio');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    final baseName = inputPath
        .split(RegExp(r'[/\\]'))
        .last
        .split('.')
        .first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${outDir.path}/${baseName}_trimmed_$timestamp.mp3';

    final command =
        '-y -ss $startSeconds -t $durationSeconds -i "$inputPath" -c:a libmp3lame -b:a 192k "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final file = File(outputPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return outputPath;
      }
    }

    return inputPath;
  }
}
