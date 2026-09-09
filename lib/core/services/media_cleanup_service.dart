import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Servicio encargado de eliminar del disco los archivos de medios
/// (imágenes y audios) que ya no están referenciados por ningún hábito,
/// categoría o recordatorio.
///
/// Esto evita acumular basura en el directorio de documentos de la app
/// cuando el usuario cambia o elimina la imagen/sonido de un hábito o
/// categoría, o cuando elimina el propio hábito/categoría.
///
/// Solo se borran archivos que viven dentro del directorio de documentos de
/// la app (donde `ImagePickerService` y `AudioExtractorService` los guardan).
/// Los archivos externos (caché, rutas del sistema, assets) nunca se tocan.
class MediaCleanupService {
  MediaCleanupService._internal();
  static final MediaCleanupService instance = MediaCleanupService._internal();

  /// Caché del directorio de documentos de la app.
  String? _docsDirPath;

  /// Devuelve la ruta del directorio de documentos de la app.
  ///
  /// Se cachea para evitar llamadas repetidas a
  /// `getApplicationDocumentsDirectory()`, que es asíncrona y relativamente
  /// costosa.
  Future<String> _getDocsDirPath() async {
    if (_docsDirPath != null) return _docsDirPath!;
    final dir = await getApplicationDocumentsDirectory();
    _docsDirPath = dir.path;
    return _docsDirPath!;
  }

  /// Devuelve `true` si [path] está dentro del directorio de documentos de
  /// la app y, por tanto, es seguro borrarlo.
  Future<bool> _isInDocsDir(String path) async {
    try {
      final docs = await _getDocsDirPath();
      final normalized = path.replaceAll('\\', '/');
      final normalizedDocs = docs.replaceAll('\\', '/');
      return normalized.startsWith(normalizedDocs);
    } catch (_) {
      return false;
    }
  }

  /// Recopila todas las rutas de medios referenciadas por el repositorio:
  /// imágenes y sonidos de hábitos, recordatorios y categorías.
  Set<String> _collectReferencedPaths(HabitsRepository repository) {
    final paths = <String>{};
    for (final habit in repository.getHabits()) {
      if (habit.imagePath != null && habit.imagePath!.isNotEmpty) {
        paths.add(habit.imagePath!);
      }
      for (final reminder in habit.reminders) {
        if (reminder.soundPath != null && reminder.soundPath!.isNotEmpty) {
          paths.add(reminder.soundPath!);
        }
      }
    }
    for (final category in repository.getCategories()) {
      if (category.imagePath != null && category.imagePath!.isNotEmpty) {
        paths.add(category.imagePath!);
      }
      if (category.defaultSoundPath != null &&
          category.defaultSoundPath!.isNotEmpty) {
        paths.add(category.defaultSoundPath!);
      }
    }
    return paths;
  }

  /// Elimina de disco los archivos de [oldPaths] que:
  /// - No estén en [keepPaths] (los medios del nuevo estado).
  /// - No estén referenciados por ningún otro hábito, categoría o recordatorio
  ///   del repositorio.
  /// - Estén dentro del directorio de documentos de la app.
  ///
  /// La operación es "best-effort": si un archivo no se puede borrar (por
  /// ejemplo, porque ya no existe o no hay permisos), se ignora silenciosamente.
  void deleteUnused({
    required List<String?> oldPaths,
    required List<String?> keepPaths,
    required HabitsRepository repository,
  }) {
    final referenced = _collectReferencedPaths(repository);
    final keep = <String>{...referenced};
    for (final p in keepPaths) {
      if (p != null && p.isNotEmpty) keep.add(p);
    }

    for (final oldPath in oldPaths) {
      if (oldPath == null || oldPath.isEmpty) continue;
      if (keep.contains(oldPath)) continue;
      _deleteIfInDocsDir(oldPath);
    }
  }

  /// Elimina [path] de disco solo si está dentro del directorio de
  /// documentos de la app. La comprobación es asíncrona pero la eliminación
  /// se realiza sin bloquear al llamador.
  void _deleteIfInDocsDir(String path) {
    // Ejecutamos en background para no bloquear la UI ni el guardado del
    // repositorio. Los errores se ignoran: es una limpieza best-effort.
    () async {
      try {
        if (!await _isInDocsDir(path)) return;
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[MediaCleanupService] No se pudo borrar $path: $e');
      }
    }();
  }
}
