import 'package:flutter/material.dart';

import 'dart:async';

import '../core/constants.dart';
import '../models/device_model.dart';
import '../screens/login_page.dart';
import '../services/auth_service.dart';
import '../services/mqtt_service.dart';
import '../services/settings_service.dart';
import '../widgets/device_card.dart';
import '../widgets/stat_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _autoRefreshTimer;

  /// Устройства, о которых знает сервер; до первых данных —
  /// знакомые контроллеры со статусом «ожидание».
  List<DeviceModel> get _devices {
    final known = MqttService.instance.deviceStatuses;
    if (known.isNotEmpty) {
      return [
        for (final entry in known.entries)
          DeviceModel(
            deviceId: entry.key,
            name: 'BM Controller ${entry.key}',
            status: entry.value,
          ),
      ];
    }
    return const [
      DeviceModel(deviceId: 'BM01', name: 'BM Controller BM01'),
      DeviceModel(deviceId: 'BM02', name: 'BM Controller BM02'),
      DeviceModel(deviceId: 'BM03', name: 'BM Controller BM03'),
    ];
  }

  @override
  void initState() {
    super.initState();
    MqttService.instance.addListener(_onMqttChanged);
    // Автообновление: каждые 10 секунд проверяем соединение
    // и перерисовываем экран.
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) {
          if (!SettingsService.instance.autoRefresh) return;
          MqttService.instance.checkConnection();
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    MqttService.instance.removeListener(_onMqttChanged);
    super.dispose();
  }

  void _onMqttChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await MqttService.instance.refresh();
    if (mounted) setState(() {});
  }

  /// Показывает аккуратное окно в правом верхнем углу
  /// с предложением выйти из аккаунта.
  void _showExitPopup(BuildContext context) {
    final user = AuthService.instance.currentUser;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрыть',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 70, right: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                          accentColor.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.person,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Вы хотите выйти?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (user != null)
                                Text(
                                  user.username,
                                  style: const TextStyle(
                                    color: secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: secondaryText,
                              side: BorderSide(
                                color:
                                Colors.white.withValues(alpha: 0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await AuthService.instance.logout();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                    (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Выйти'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _devices
        .where((device) => device.status == DeviceStatus.online)
        .length;
    final serverConnected = MqttService.instance.isConnected;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: accentColor,
      backgroundColor: cardColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BM MONITOR',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        serverConnected
                            ? 'Сервер подключён'
                            : 'Сервер не подключён',
                        style: TextStyle(
                          color: serverConnected
                              ? accentColor
                              : Colors.redAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showExitPopup(context),
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: secondaryText,
                    size: 30,
                  ),
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
              child: Row(
                children: [
                  Icon(
                    serverConnected
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: serverConnected
                        ? accentColor
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      serverConnected
                          ? 'Подключено к HiveMQ Cloud. Данные '
                          'обновляются в реальном времени.'
                          : 'Нет соединения с сервером. Потяните '
                          'вниз, чтобы обновить.',
                      style: const TextStyle(
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
      ),
    );
  }
}