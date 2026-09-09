import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getString(String key) async {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService not initialized');
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService not initialized');
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService not initialized');
    await prefs.remove(key);
  }
}
