import 'package:flutter/material.dart';

import 'core/app.dart';
import 'services/mqtt_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Уведомления и подключение к серверу — сразу при запуске.
  await NotificationService.instance.init();
  MqttService.instance.connect();

  runApp(const BMMonitorApp());
}
