import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/mqtt_service.dart';
import '../widgets/hacker_raw_view.dart';

/// Экран диагностики: «хакерский» терминал сырых кадров ESP32
/// с расшифровкой по выбранному устройству + история пакетов.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  String? _selectedDeviceId;
  bool _decodedMode = true; // true = расшифровка, false = голый HEX

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
                icon: const Icon(
                  Icons.delete_outline,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),

        // Выбор устройства-источника.
        if (deviceIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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

        // Переключатель режима терминала.
        if (_selectedDeviceId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _ModeButton(
                    label: 'Расшифровка',
                    icon: Icons.qr_code_scanner,
                    active: _decodedMode,
                    onTap: () => setState(() => _decodedMode = true),
                  ),
                  _ModeButton(
                    label: 'Сырой HEX',
                    icon: Icons.hexagon_outlined,
                    active: !_decodedMode,
                    onTap: () => setState(() => _decodedMode = false),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 14),

        // Терминал.
        if (_selectedDeviceId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HackerRawView(
              deviceId: _selectedDeviceId!,
              decodedMode: _decodedMode,
            ),
          ),

        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'История пакетов',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: deviceIds.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.terminal,
                          size: 65,
                          color: accentColor,
                        ),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? accentColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? accentColor : secondaryText,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? accentColor : secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
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
