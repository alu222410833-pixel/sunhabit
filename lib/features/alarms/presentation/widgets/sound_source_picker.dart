import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sunhabit/core/services/audio_extractor_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

/// Helper reutilizable para elegir la fuente del sonido de una alarma.
///
/// Muestra un bottom sheet con dos opciones:
/// - **Archivo de audio**: el usuario elige un audio y se usa tal cual.
/// - **Extraer audio de un video**: el usuario elige un video y se extrae su
///   pista de audio con [AudioExtractorService] (FFmpegKit) a un `.m4a`
///   persistente.
///
/// En ambos casos devuelve la ruta de un archivo de audio válido (ya extraído
/// si venía de un video), o `null` si el usuario cancela o algo falla.
class SoundSourcePicker {
  SoundSourcePicker._();

  /// Muestra el selector y devuelve la ruta del audio resultante.
  ///
  /// Muestra [progressText] mientras se extrae audio de un video.
  static Future<String?> pick(BuildContext context) async {
    final choice = await showModalBottomSheet<_SoundSource>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Elegir sonido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.neonGreen,
                ),
                title: const Text('Archivo de audio'),
                subtitle: const Text(
                  'Elige un archivo de sonido existente',
                ),
                onTap: () => Navigator.pop(context, _SoundSource.audio),
              ),
              ListTile(
                leading: const Icon(
                  Icons.movie_creation_rounded,
                  color: AppColors.neonGreen,
                ),
                title: const Text('Extraer audio de un video'),
                subtitle: const Text(
                  'Selecciona un video y se extraerá su audio',
                ),
                onTap: () => Navigator.pop(context, _SoundSource.video),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return null;

    switch (choice) {
      case _SoundSource.audio:
        return _pickAudio();
      case _SoundSource.video:
        if (!context.mounted) return null;
        return _pickVideoAndExtract(context);
    }
  }

  static Future<String?> _pickAudio() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result.isEmpty) return null;
    return result.single.path;
  }

  static Future<String?> _pickVideoAndExtract(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    if (result.isEmpty) return null;
    final videoPath = result.single.path;
    if (videoPath == null || videoPath.isEmpty) return null;
    if (!context.mounted) return null;

    // Mostrar indicador de progreso mientras FFmpeg extrae el audio.
    String? extractedPath;
    bool extractionFailed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<String?>(
            future: AudioExtractorService().extractAudio(videoPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.neonGreen),
                    SizedBox(height: 16),
                    Text('Extrayendo audio del video…'),
                  ],
                );
              }
              extractedPath = snapshot.data;
              extractionFailed = snapshot.data == null;
              // Cerrar el diálogo en el siguiente frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    if (extractionFailed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo extraer el audio del video'),
          backgroundColor: AppColors.surfaceHighest,
        ),
      );
    }
    return extractedPath;
  }
}

enum _SoundSource { audio, video }
