import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/device_model.dart';
import 'notification_service.dart';

/// Один сырый пакет, полученный от ESP32.
class RawPacket {
  /// Идентификатор устройства (например, «BM01»).
  final String deviceId;

  /// Порядковый номер пакета от устройства.
  final int sequence;

  /// Аптайм устройства в миллисекундах на момент отправки.
  final int uptimeMs;

  /// Длина пакета в байтах.
  final int length;

  /// Сырые данные в HEX.
  final String hex;

  /// Время получения пакета приложением.
  final DateTime receivedAt;

  const RawPacket({
    required this.deviceId,
    required this.sequence,
    required this.uptimeMs,
    required this.length,
    required this.hex,
    required this.receivedAt,
  });

  factory RawPacket.fromEsp32Json(Map<String, dynamic> json) {
    return RawPacket(
      deviceId: (json['device'] ?? 'UNKNOWN').toString(),
      sequence: (json['seq'] as num?)?.toInt() ?? 0,
      uptimeMs: (json['uptime_ms'] as num?)?.toInt() ?? 0,
      length: (json['length'] as num?)?.toInt() ?? 0,
      hex: (json['hex'] ?? '').toString(),
      receivedAt: DateTime.now(),
    );
  }
}

/// Сервис подключения к MQTT-брокеру (HiveMQ Cloud) и приёма
/// сырых данных от ESP32.
///
/// Топики:
///  - bm/<deviceId>/raw    — сырые HEX-пакеты;
///  - bm/<deviceId>/status — {"device":"..","online":true/false}.
///
/// Подключение устанавливается при старте приложения, при разрыве
/// соединение восстанавливается автоматически.
class MqttService extends ChangeNotifier {
  MqttService._();
  static final MqttService instance = MqttService._();

  /// Запуск сторожа таймаута устройств.
  void startWatchdog() {
    _watchdogTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkDeviceTimeouts(),
    );
  }

  void _checkDeviceTimeouts() {
    final now = DateTime.now();
    var changed = false;

    _lastSeenAt.forEach((deviceId, lastSeen) {
      if (now.difference(lastSeen) <= deviceTimeout) return;
      if (_deviceStatuses[deviceId] == DeviceStatus.offline) return;

      _deviceStatuses[deviceId] = DeviceStatus.offline;
      NotificationService.instance
          .deviceStatus(deviceId, online: false);
      changed = true;
    });

    if (changed) notifyListeners();
  }

  // ---- Параметры сервера ----
  static const String host =
      'b7c39db3cd51413696b0b4185988fef9.s1.eu.hivemq.cloud';
  static const int port = 8883;
  static const String username = 'Orlando';
  static const String password = '146010qwW+';

  static const String _rawTopic = 'bm/+/raw';
  static const String _statusTopic = 'bm/+/status';

  MqttServerClient? _client;

  bool _connected = false;
  bool get isConnected => _connected;

  bool _connecting = false;
  bool _manualDisconnect = false;

  /// Последнее время успешного соединения.
  DateTime? lastConnectedAt;

  /// Сырые пакеты, сгруппированные по устройствам.
  final Map<String, List<RawPacket>> _packetsByDevice = {};

  /// Статусы устройств по статус-топикам.
  final Map<String, DeviceStatus> _deviceStatuses = {};

  /// Время последнего признака жизни устройства (пакет или статус).
  final Map<String, DateTime> _lastSeenAt = {};

  /// Если от устройства нет данных дольше этого — считаем офлайн.
  static const Duration deviceTimeout = Duration(seconds: 40);

  Timer? _watchdogTimer;

  Map<String, List<RawPacket>> get packetsByDevice =>
      Map.unmodifiable(_packetsByDevice);

  Map<String, DeviceStatus> get deviceStatuses =>
      Map.unmodifiable(_deviceStatuses);

  List<String> get deviceIds => _packetsByDevice.keys.toList();

  // ================= ПОДКЛЮЧЕНИЕ =================

  Future<void> connect() async {
    if (_connected || _connecting) return;
    _connecting = true;
    _manualDisconnect = false;
    notifyListeners();

    final clientId =
        'BM_Monitor_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient.withPort(host, clientId, port);
    client.secure = true;
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onAutoReconnect = _onAutoReconnect;
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .startClean();

    try {
      await client.connect();
    } catch (_) {
      _connecting = false;
      _client = null;
      _setConnected(false);
      _scheduleReconnect();
      return;
    }

    _connecting = false;

    if (client.connectionStatus!.state ==
        MqttConnectionState.connected) {
      _client = client;
      _subscribe();
      _onConnected();
    } else {
      client.disconnect();
      _client = null;
      _setConnected(false);
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _client?.disconnect();
    _client = null;
    _setConnected(false);
  }

  /// Проверка соединения: при обрыве — переподключение.
  Future<void> checkConnection() async {
    final client = _client;
    if (_connected &&
        client != null &&
        client.connectionStatus!.state ==
            MqttConnectionState.connected) {
      return;
    }
    await connect();
  }

  /// Обновление данных по запросу (pull-to-refresh):
  /// проверяет соединение и оповещает слушателей.
  Future<void> refresh() async {
    await checkConnection();
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (!_connected && !_connecting && !_manualDisconnect) {
        connect();
      }
    });
  }

  void _onConnected() {
    lastConnectedAt = DateTime.now();
    _setConnected(true);
    NotificationService.instance.serverStatus(connected: true);
  }

  void _onDisconnected() {
    final wasConnected = _connected;
    _setConnected(false);
    if (wasConnected) {
      NotificationService.instance.serverStatus(connected: false);
    }
    _scheduleReconnect();
  }

  void _onAutoReconnect() {
    debugPrint('MQTT: автоматическое переподключение...');
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    notifyListeners();
  }

  // ================= ПОДПИСКИ =================

  void _subscribe() {
    final client = _client;
    if (client == null) return;

    client
      ..subscribe(_rawTopic, MqttQos.atLeastOnce)
      ..subscribe(_statusTopic, MqttQos.atLeastOnce);

    client.updates!.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final topic = event.topic;
      final message = event.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );

      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) continue;

        if (topic.endsWith('/raw') && decoded['type'] == 'raw') {
          _handleRawPacket(RawPacket.fromEsp32Json(decoded));
        } else if (topic.endsWith('/status')) {
          _handleStatusMessage(decoded);
        }
      } catch (_) {
        // Невалидный пакет — игнорируем.
      }
    }
  }

  void _handleRawPacket(RawPacket packet) {
    _packetsByDevice.putIfAbsent(packet.deviceId, () => []).add(packet);
    _lastSeenAt[packet.deviceId] = DateTime.now();

    final list = _packetsByDevice[packet.deviceId]!;
    if (list.length > 200) {
      _packetsByDevice[packet.deviceId] =
          list.sublist(list.length - 200);
    }

    // Пакет пришёл — устройство явно в сети.
    _updateDeviceStatus(packet.deviceId, true);
    notifyListeners();
  }

  void _handleStatusMessage(Map<String, dynamic> json) {
    final deviceId = (json['device'] ?? '').toString();
    if (deviceId.isEmpty) return;
    final online = json['online'] == true;
    if (online) _lastSeenAt[deviceId] = DateTime.now();
    _updateDeviceStatus(deviceId, online);
    notifyListeners();
  }

  void _updateDeviceStatus(String deviceId, bool online) {
    final newStatus =
        online ? DeviceStatus.online : DeviceStatus.offline;
    final old = _deviceStatuses[deviceId];

    if (old == newStatus) return;

    // Уведомляем об отключении известного устройства
    // или о новом подключении.
    if (old != null || online) {
      NotificationService.instance
          .deviceStatus(deviceId, online: online);
    }
    _deviceStatuses[deviceId] = newStatus;
  }

  void clearHistory() {
    _packetsByDevice.clear();
    notifyListeners();
  }
}
