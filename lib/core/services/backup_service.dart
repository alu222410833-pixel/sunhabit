import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sunhabit/core/services/storage_service.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Servicio para exportar e importar los datos de la aplicación.
///
/// El backup se guarda como un archivo JSON que contiene las tres keys que
/// [HabitsRepository] persiste en [StorageService]: hábitos, categorías y logs.
/// Esto permite al usuario guardar sus datos en el teléfono y restaurarlos
/// más tarde o en otro dispositivo.
///
/// Además, `data.media` lleva embebidos en base64 los archivos referenciados
/// por los datos (imagen «Mi porqué», imagen/icono de categoría, sonidos de
/// recordatorios y sonido por defecto de categoría). Las rutas guardadas en
/// el JSON son absolutas del dispositivo de origen, así que al importar se
/// reescriben a `documents/backup_media/` del dispositivo actual. La clave
/// `media` es aditiva: backups antiguos sin ella y apps antiguas leyendo un
/// backup nuevo siguen funcionando (solo faltarían los archivos).
class BackupService {
  final StorageService _storage;

  BackupService({StorageService? storage})
      : _storage = storage ?? StorageService();

  static const String _backupApp = 'sunhabit';
  static const int _backupVersion = 1;

  /// Exporta los datos actuales a un archivo JSON.
  ///
  /// Abre el diálogo "Guardar como" del sistema para que el usuario elija la
  /// carpeta de destino (Descargas, Drive, etc.) y pueda cambiar el nombre.
  /// Devuelve la [Uri] donde se guardó el archivo, o `null` si el usuario
  /// canceló el diálogo.
  ///
  /// Lanza [BackupException] si no se pueden leer los datos o escribir el
  /// archivo.
  Future<Uri?> export() async {
    final payload = await _buildPayload();
    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

    final fileName = 'sunhabit_backup_${_fileNameDate(DateTime.now())}.json';
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(jsonString),
      mimeType: 'application/json',
      dialogTitle: 'Guardar backup de SunHabit',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  }

  /// Importa datos desde un archivo JSON seleccionado por el usuario.
  ///
  /// Devuelve `true` si se importó correctamente, `false` si el usuario
  /// canceló el diálogo.
  ///
  /// Lanza [BackupException] si el archivo no tiene el formato esperado.
  Future<bool> import() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) return false;

    final content = await _readFile(file);
    final payload = _parsePayload(content);

    // Restaurar los medios embebidos a disco y reescribir las rutas
    // absolutas del dispositivo de origen por las nuevas locales.
    final pathMap = await _restoreMediaFiles(payload.media);
    final habits = _rewriteMediaPaths(payload.habits, pathMap);
    final categories = _rewriteMediaPaths(payload.categories, pathMap);

    await _storage.setString(HabitsRepository.habitsKey, habits);
    await _storage.setString(HabitsRepository.categoriesKey, categories);
    await _storage.setString(HabitsRepository.logsKey, payload.logs);
    return true;
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final habits = await _storage.getString(HabitsRepository.habitsKey) ?? '[]';
    final categories =
        await _storage.getString(HabitsRepository.categoriesKey) ?? '[]';
    final logs = await _storage.getString(HabitsRepository.logsKey) ?? '[]';
    final media = await _collectMedia(habits, categories);

    return {
      'version': _backupVersion,
      'app': _backupApp,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        HabitsRepository.habitsKey: habits,
        HabitsRepository.categoriesKey: categories,
        HabitsRepository.logsKey: logs,
        if (media.isNotEmpty) 'media': media,
      },
    };
  }

  /// Campos de nivel superior que pueden contener rutas de archivos,
  /// tanto en hábitos como en categorías.
  static const _mediaPathFields = [
    'imagePath',
    'whyImagePath',
    'defaultSoundPath',
  ];

  /// Extrae las rutas de medios referenciadas en un JSON de lista
  /// (hábitos o categorías): campos directos + `soundPath` de cada
  /// recordatorio anidado.
  Set<String> _collectMediaPaths(String jsonList) {
    final paths = <String>{};
    try {
      for (final item
          in (jsonDecode(jsonList) as List).whereType<Map<String, dynamic>>()) {
        for (final field in _mediaPathFields) {
          final value = item[field];
          if (value is String && value.isNotEmpty) paths.add(value);
        }
        final reminders = item['reminders'];
        if (reminders is List) {
          for (final r in reminders.whereType<Map<String, dynamic>>()) {
            final sound = r['soundPath'];
            if (sound is String && sound.isNotEmpty) paths.add(sound);
          }
        }
      }
    } catch (_) {}
    return paths;
  }

  /// Lee los archivos referenciados por hábitos y categorías y los
  /// embebe como `{'path': <ruta original>, 'data': <base64>}`.
  /// Los archivos que ya no existen se omiten silenciosamente.
  Future<List<Map<String, String>>> _collectMedia(
    String habitsJson,
    String categoriesJson,
  ) async {
    final paths = {
      ..._collectMediaPaths(habitsJson),
      ..._collectMediaPaths(categoriesJson),
    };
    final media = <Map<String, String>>[];
    for (final path in paths) {
      try {
        final file = File(path);
        if (!file.existsSync()) continue;
        media.add({
          'path': path,
          'data': base64Encode(await file.readAsBytes()),
        });
      } catch (_) {}
    }
    return media;
  }

  /// Escribe los medios embebidos en `documents/backup_media/` y
  /// devuelve el mapa ruta original → ruta restaurada.
  ///
  /// El nombre de cada archivo restaurado lleva prefijo de índice para
  /// evitar colisiones entre archivos con el mismo basename. Si el
  /// directorio de documentos no está disponible (tests), devuelve un
  /// mapa vacío y las rutas del backup se conservan tal cual.
  Future<Map<String, String>> _restoreMediaFiles(
    List<Map<String, String>> media,
  ) async {
    if (media.isEmpty) return const {};
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/backup_media');
      if (!dir.existsSync()) await dir.create(recursive: true);
      final map = <String, String>{};
      var index = 0;
      for (final entry in media) {
        final originalPath = entry['path'];
        final encoded = entry['data'];
        if (originalPath == null || encoded == null) continue;
        try {
          final basename = originalPath.split(RegExp(r'[\\/]')).last;
          final target = File('${dir.path}/${index}_$basename');
          await target.writeAsBytes(base64Decode(encoded), flush: true);
          map[originalPath] = target.path;
          index++;
        } catch (_) {}
      }
      return map;
    } catch (_) {
      return const {};
    }
  }

  /// Reescribe en un JSON de lista (hábitos o categorías) las rutas de
  /// medios presentes en [pathMap], incluido el `soundPath` de los
  /// recordatorios anidados en cada hábito.
  String _rewriteMediaPaths(String jsonList, Map<String, String> pathMap) {
    if (pathMap.isEmpty) return jsonList;
    try {
      final list = jsonDecode(jsonList) as List;
      for (final item in list.whereType<Map<String, dynamic>>()) {
        for (final field in _mediaPathFields) {
          final value = item[field];
          if (value is String && pathMap.containsKey(value)) {
            item[field] = pathMap[value];
          }
        }
        final reminders = item['reminders'];
        if (reminders is List) {
          for (final r in reminders.whereType<Map<String, dynamic>>()) {
            final sound = r['soundPath'];
            if (sound is String && pathMap.containsKey(sound)) {
              r['soundPath'] = pathMap[sound];
            }
          }
        }
      }
      return jsonEncode(list);
    } catch (_) {
      return jsonList;
    }
  }

  Future<String> _readFile(PlatformFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes);
    } catch (e) {
      throw BackupException('No se pudo leer el archivo seleccionado.');
    }
  }

  _BackupPayload _parsePayload(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['app'] != _backupApp) {
      throw BackupException('El archivo no es un backup de SunHabit.');
    }
    if (json['version'] != _backupVersion) {
      throw BackupException('Versión de backup no soportada.');
    }

    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw BackupException('Formato de backup no válido.');
    }

    final habits = data[HabitsRepository.habitsKey] as String?;
    final categories = data[HabitsRepository.categoriesKey] as String?;
    final logs = data[HabitsRepository.logsKey] as String?;
    if (habits == null || categories == null || logs == null) {
      throw BackupException('El backup está incompleto.');
    }

    // Medios embebidos (aditivo, ausente en backups antiguos). Si el
    // formato es inesperado se ignora: es mejor importar sin medios
    // que rechazar el backup entero.
    final media = <Map<String, String>>[];
    final rawMedia = data['media'];
    if (rawMedia is List) {
      for (final entry in rawMedia.whereType<Map<String, dynamic>>()) {
        final path = entry['path'];
        final encoded = entry['data'];
        if (path is String && encoded is String) {
          media.add({'path': path, 'data': encoded});
        }
      }
    }

    // Validar que el JSON interno de cada clave sea una lista decodable
    // ANTES de escribir en storage: si se importara un payload corrupto,
    // `_load` no podría parsearlo y reemplazaría los datos reales con
    // los hábitos de ejemplo.
    for (final entry in {
      'hábitos': habits,
      'categorías': categories,
      'logs': logs,
    }.entries) {
      try {
        if (jsonDecode(entry.value) is! List) {
          throw const FormatException('expected a JSON list');
        }
      } catch (_) {
        throw BackupException('El backup tiene los ${entry.key} corruptos.');
      }
    }

    return _BackupPayload(habits, categories, logs, media);
  }

  String _fileNameDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

class BackupException implements Exception {
  final String message;
  BackupException(this.message);

  @override
  String toString() => message;
}

class _BackupPayload {
  final String habits;
  final String categories;
  final String logs;
  final List<Map<String, String>> media;

  const _BackupPayload(this.habits, this.categories, this.logs, this.media);
}
