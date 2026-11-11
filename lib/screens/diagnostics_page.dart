import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/mqtt_service.dart';

/// Экран диагностики: сырые HEX-пакеты от всех ESP32,
/// сгруппированные по устройствам.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    MqttService.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    MqttService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = MqttService.instance;
    final deviceIds = mqtt.deviceIds;

    // Автовыбор устройства, если ещё не выбрано.
    if (_selectedDeviceId == null && deviceIds.isNotEmpty) {
      _selectedDeviceId = deviceIds.first;
    }
    if (_selectedDeviceId != null && !deviceIds.contains(_selectedDeviceId)) {
      _selectedDeviceId = deviceIds.isEmpty ? null : deviceIds.first;
    }

    final packets =
        _selectedDeviceId == null ? <RawPacket>[] : (
            mqtt.packetsByDevice[_selectedDeviceId!] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок и статус подключения.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Диагностика',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Сырые данные от устройств ESP32',
                      style: TextStyle(color: secondaryText),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Очистить историю',
                onPressed: mqtt.clearHistory,
                icon: const Icon(Icons.delete_outline,
                    color: secondaryText),
              ),
            ],
          ),
        ),

        // Выбор устройства-источника.
        if (deviceIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final id in deviceIds) ...[
                    ChoiceChip(
                      label: Text(id),
                      selected: _selectedDeviceId == id,
                      onSelected: (_) =>
                          setState(() => _selectedDeviceId = id),
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _selectedDeviceId == id
                            ? accentColor
                            : secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: _selectedDeviceId == id
                            ? accentColor
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      backgroundColor: cardColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Список пакетов (новые сверху).
        Expanded(
          child: deviceIds.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.terminal,
                            size: 65, color: accentColor),
                        SizedBox(height: 20),
                        Text(
                          'Ожидание данных',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Сырые пакеты от ESP32 появятся здесь '
                          'после подключения к MQTT-брокеру.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: packets.length,
                  itemBuilder: (context, index) {
                    final packet =
                        packets[packets.length - 1 - index];
                    return _PacketTile(
                      packet: packet,
                      time: _formatTime(packet.receivedAt),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PacketTile extends StatelessWidget {
  final RawPacket packet;
  final String time;

  const _PacketTile({required this.packet, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${packet.sequence}',
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${packet.length} байт',
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'uptime: ${packet.uptimeMs} мс',
            style: const TextStyle(
              color: secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            packet.hex,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.lightGreenAccent,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
