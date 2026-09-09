import 'package:sunhabit/core/services/storage_service.dart';

/// Implementación en memoria de [StorageService] para tests.
///
/// Permite crear instancias aisladas de [HabitsRepository] sin depender
/// de `SharedPreferences` ni de singletons globales.
class FakeStorageService implements StorageService {
  final Map<String, String> _values = {};

  @override
  Future<void> init() async {}

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  /// Limpia todos los valores almacenados.
  void clear() => _values.clear();
}
