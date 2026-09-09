import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:sunhabit/core/services/storage_service.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Servicio para exportar e importar los datos de la aplicación.
///
/// El backup se guarda como un archivo JSON que contiene las tres keys que
/// [HabitsRepository] persiste en [StorageService]: hábitos, categorías y logs.
/// Esto permite al usuario guardar sus datos en el teléfono y restaurarlos
/// más tarde o en otro dispositivo.
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

    await _storage.setString(HabitsRepository.habitsKey, payload.habits);
    await _storage.setString(
      HabitsRepository.categoriesKey,
      payload.categories,
    );
    await _storage.setString(HabitsRepository.logsKey, payload.logs);
    return true;
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final habits = await _storage.getString(HabitsRepository.habitsKey) ?? '[]';
    final categories =
        await _storage.getString(HabitsRepository.categoriesKey) ?? '[]';
    final logs = await _storage.getString(HabitsRepository.logsKey) ?? '[]';

    return {
      'version': _backupVersion,
      'app': _backupApp,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        HabitsRepository.habitsKey: habits,
        HabitsRepository.categoriesKey: categories,
        HabitsRepository.logsKey: logs,
      },
    };
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

    return _BackupPayload(habits, categories, logs);
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

  const _BackupPayload(this.habits, this.categories, this.logs);
}
