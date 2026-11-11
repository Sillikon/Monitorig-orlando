import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'activity_service.dart';
import 'settings_service.dart';

/// Сервис локальных push-уведомлений.
///
/// Уведомляет о:
///  - подключении/отключении MQTT-сервера;
///  - подключении/отключении ESP32 (по статус-топикам);
///  - входе/выходе пользователей (через журнал активности).
///
/// Уважает настройки: «Push-уведомления» и «Звуковые оповещения».
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  int _notificationId = 0;

  /// Сколько записей журнала уже обработано —
  /// чтобы не присылать старые события.
  int _seenEntries = 0;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Запрашиваем разрешения (Android 13+, iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);

    _seenEntries = ActivityService.instance.entries.length;
    ActivityService.instance.addListener(_watchActivity);
  }

  NotificationDetails _details() {
    final withSound = SettingsService.instance.soundAlerts;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        withSound ? 'bm_alerts' : 'bm_silent',
        'BM Monitor',
        channelDescription: 'События мониторинга оборудования',
        importance: Importance.high,
        priority: Priority.high,
        playSound: withSound,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<void> _show(String title, String body) async {
    if (!SettingsService.instance.notificationsEnabled) return;
    try {
      await _plugin.show(
        _notificationId++,
        title,
        body,
        _details(),
      );
    } catch (_) {
      // Уведомления недоступны — не ломаем приложение.
    }
  }

  /// Сервер подключён / отключён.
  void serverStatus({required bool connected}) {
    _show(
      connected ? 'Сервер подключён' : 'Сервер отключён',
      connected
          ? 'Соединение с MQTT-брокером установлено'
          : 'Потеряно соединение с MQTT-брокером',
    );
  }

  /// ESP32 устройство подключилось / отключилось.
  void deviceStatus(String deviceId, {required bool online}) {
    _show(
      online ? 'Устройство в сети' : 'Устройство отключено',
      '$deviceId ${online ? 'подключено' : 'более не в сети'}',
    );
  }

  /// Появились новые записи в журнале активности —
  /// уведомляем о входах/выходах пользователей.
  void _watchActivity() {
    final entries = ActivityService.instance.entries;
    if (entries.length <= _seenEntries) {
      _seenEntries = entries.length;
      return;
    }

    final fresh = entries.take(entries.length - _seenEntries);
    for (final entry in fresh) {
      switch (entry.event) {
        case ActivityEvent.login:
          _show('Вход пользователя', '${entry.username} вошёл в систему');
          break;
        case ActivityEvent.logout:
          _show('Выход пользователя', '${entry.username} вышел из системы');
          break;
        default:
          break;
      }
    }
    _seenEntries = entries.length;
  }
}
