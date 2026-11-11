import 'package:flutter/foundation.dart';

/// Сервис настроек приложения.
///
/// Значения хранятся в памяти; позже перенести в
/// shared_preferences / на сервер.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  bool _notificationsEnabled = true;
  bool _soundAlerts = true;
  bool _autoRefresh = true;

  /// Push-уведомления о событиях (сервер, устройства, операторы).
  bool get notificationsEnabled => _notificationsEnabled;

  /// Звуковой сигнал уведомлений.
  bool get soundAlerts => _soundAlerts;

  /// Автообновление данных на экране «Обзор».
  bool get autoRefresh => _autoRefresh;

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setSoundAlerts(bool value) {
    _soundAlerts = value;
    notifyListeners();
  }

  void setAutoRefresh(bool value) {
    _autoRefresh = value;
    notifyListeners();
  }
}
