import 'package:shared_preferences/shared_preferences.dart';

/// Сервис локального хранения (токены, настройки).
///
/// Данные сохраняются через SharedPreferences и переживают
/// перезапуск приложения.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> save(String key, String value) async {
    final prefs = await _storage;
    await prefs.setString(key, value);
  }

  Future<String?> read(String key) async {
    final prefs = await _storage;
    return prefs.getString(key);
  }

  Future<void> delete(String key) async {
    final prefs = await _storage;
    await prefs.remove(key);
  }
}
