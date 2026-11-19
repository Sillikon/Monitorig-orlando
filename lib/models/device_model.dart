import 'package:flutter/material.dart';

/// Отображаемое имя устройства по его идентификатору.
String deviceDisplayName(String deviceId) {
  switch (deviceId.toUpperCase()) {
    case 'BM01':
      return 'Камера газации №1';
    case 'BM02':
      return 'Камера газации №2';
    case 'BM03':
      return 'Камера газации №3';
    default:
      return 'BM Controller $deviceId';
  }
}

/// Статус подключения устройства.
enum DeviceStatus { online, offline, waiting }

/// Модель устройства BM.
class DeviceModel {
  final String deviceId;
  final String name;
  final DeviceStatus status;

  const DeviceModel({
    required this.deviceId,
    required this.name,
    this.status = DeviceStatus.waiting,
  });

  /// Текст статуса для отображения в UI.
  String get statusLabel => switch (status) {
        DeviceStatus.online => 'В сети',
        DeviceStatus.offline => 'Не в сети',
        DeviceStatus.waiting => 'Ожидание подключения',
      };

  /// Цвет индикатора статуса.
  Color get statusColor => switch (status) {
        DeviceStatus.online => const Color(0xFF39D5A0),
        DeviceStatus.offline => Colors.redAccent,
        DeviceStatus.waiting => Colors.orangeAccent,
      };
}
