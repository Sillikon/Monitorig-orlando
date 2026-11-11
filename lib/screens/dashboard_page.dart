import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/device_model.dart';
import '../widgets/device_card.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const List<DeviceModel> _devices = [
    DeviceModel(deviceId: 'BM01', name: 'BM Controller 01'),
    DeviceModel(deviceId: 'BM02', name: 'BM Controller 02'),
    DeviceModel(deviceId: 'BM03', name: 'BM Controller 03'),
  ];

  @override
  Widget build(BuildContext context) {
    final onlineCount = _devices
        .where((device) => device.status == DeviceStatus.online)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.memory,
                  color: accentColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BM MONITOR',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Equipment monitoring system',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.account_circle_outlined,
                color: secondaryText,
                size: 30,
              ),
            ],
          ),

          const SizedBox(height: 32),

          const Text(
            'Панель управления',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Состояние подключенного оборудования',
            style: TextStyle(color: secondaryText),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Устройства',
                  value: _devices.length.toString(),
                  icon: Icons.devices,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'В сети',
                  value: onlineCount.toString(),
                  icon: Icons.wifi,
                  color: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'Мои устройства',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          for (var i = 0; i < _devices.length; i++) ...[
            DeviceCard(device: _devices[i]),
            if (i < _devices.length - 1) const SizedBox(height: 12),
          ],

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blueAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ожидание подключения к серверу. '
                    'Данные появятся после подключения.',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
