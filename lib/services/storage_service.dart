/// Сервис локального хранения (токены, настройки).
///
/// Данные держатся в памяти и пропадают при перезапуске.
/// Позже заменить на shared_preferences / hive.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final Map<String, String> _memory = {};

  Future<void> save(String key, String value) async {
    _memory[key] = value;
  }

  Future<String?> read(String key) async => _memory[key];

  Future<void> delete(String key) async {
    _memory.remove(key);
  }
}