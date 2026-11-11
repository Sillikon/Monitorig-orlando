import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/device_model.dart';

class DeviceDetailsPage extends StatelessWidget {
  final DeviceModel device;

  const DeviceDetailsPage({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.deviceId)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.name,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Устройство пока не подключено.',
              style: TextStyle(color: secondaryText),
            ),
            const SizedBox(height: 20),
            const Text(
              'Здесь появятся данные BM, история пакетов '
              'и параметры подключения.',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
