import 'package:flutter/foundation.dart';

/// Тип события активности пользователя.
enum ActivityEvent {
  /// Успешный вход в систему.
  login,

  /// Явный выход из системы (кнопка «Выйти»).
  logout,

  /// Приложение открыто / развёрнуто.
  appOpened,

  /// Приложение свёрнуто (ушло в фон).
  appHidden,
}

/// Одна запись журнала активности.
class ActivityEntry {
  final String username;
  final ActivityEvent event;
  final DateTime timestamp;

  const ActivityEntry({
    required this.username,
    required this.event,
    required this.timestamp,
  });

  /// Человекочитаемое описание события.
  String get eventLabel => switch (event) {
        ActivityEvent.login => 'Вход в систему',
        ActivityEvent.logout => 'Выход из системы',
        ActivityEvent.appOpened => 'Приложение открыто',
        ActivityEvent.appHidden => 'Приложение свёрнуто',
      };
}

/// Сервис журнала активности пользователей.
///
/// Хранится в памяти (как и StorageService); позже перенести
/// на сервер вместе с авторизацией.
class ActivityService extends ChangeNotifier {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  final List<ActivityEntry> _entries = [];

  /// Все записи, от новых к старым.
  List<ActivityEntry> get entries => _entries.reversed.toList();

  /// Записи конкретного пользователя, от новых к старым.
  List<ActivityEntry> entriesFor(String username) =>
      entries.where((e) => e.username == username).toList();

  void log(String username, ActivityEvent event) {
    _entries.add(
      ActivityEntry(
        username: username,
        event: event,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
