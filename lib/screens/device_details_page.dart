import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/device_model.dart';
import '../services/bm_decoder.dart';
import '../services/mqtt_service.dart';

/// Экран конкретного BM-контроллера:
/// статус, режим, температура, время программы, состояние
/// агрегатов и светодиодные линейки — всё расшифровано
/// из последнего кадра.
class DeviceDetailsPage extends StatefulWidget {
  final DeviceModel device;

  const DeviceDetailsPage({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  @override
  void initState() {
    super.initState();
    MqttService.instance.addListener(_onData);
  }

  @override
  void dispose() {
    MqttService.instance.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  BmFrame? get _frame {
    final packets =
        MqttService.instance.packetsByDevice[widget.device.deviceId];
    if (packets == null || packets.isEmpty) return null;
    return BmDecoder.instance.decodeHex(packets.last.hex);
  }

  RawPacket? get _lastPacket {
    final packets =
        MqttService.instance.packetsByDevice[widget.device.deviceId];
    if (packets == null || packets.isEmpty) return null;
    return packets.last;
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    final packet = _lastPacket;
    final device = widget.device;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => MqttService.instance.refresh(),
          color: accentColor,
          backgroundColor: cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Шапка ----
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BM Controller ${device.deviceId}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 9,
                                color: device.statusColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                device.statusLabel,
                                style: const TextStyle(
                                  color: secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                        size: 26,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (frame == null) ...[
                  // Устройство ещё не прислало данных.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.sensors_off,
                          size: 44,
                          color: secondaryText,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Устройство пока не подключено',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Данные появятся, как только ESP32 начнёт '
                          'принимать кадры от контроллера.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ---- Режим работы ----
                  _SectionBlock(
                    title: 'Режим работы',
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          frame.mode ?? '—',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---- Температура + время программы ----
                  Row(
                    children: [
                      Expanded(
                        child: _ValueCard(
                          label: 'Значение',
                          value: frame.valueText.isEmpty
                              ? '—'
                              : frame.valueText,
                          unit: '°C',
                          icon: Icons.thermostat,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ValueCard(
                          label: 'Время программы',
                          value:
                              frame.clockText.isEmpty ? '—' : frame.clockText,
                          unit: 'час.',
                          icon: Icons.schedule,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---- Светодиодные линейки ----
                  _SectionBlock(
                    title: 'Датчики температуры',
                    child: _LedRow(lit: frame.sensorLeds),
                  ),

                  const SizedBox(height: 10),

                  _SectionBlock(
                    title: 'Дни программы',
                    child: _LedRow(lit: frame.dayLeds),
                  ),

                  const SizedBox(height: 14),

                  // ---- Агрегаты ----
                  _SectionBlock(
                    title: 'Состояние агрегатов',
                    child: Column(
                      children: [
                        for (final relay in frame.relays)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  relay.on
                                      ? Icons.power_settings_new
                                      : Icons.power_settings_new,
                                  size: 18,
                                  color: relay.on
                                      ? accentColor
                                      : secondaryText,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    relay.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: relay.on
                                        ? accentColor.withValues(alpha: 0.15)
                                        : Colors.white
                                            .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    relay.on ? 'ВКЛ' : 'ВЫКЛ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: relay.on
                                          ? accentColor
                                          : secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---- Техническая информация ----
                  _SectionBlock(
                    title: 'Технически данные',
                    child: Column(
                      children: [
                        if (packet != null) ...[
                          _TechRow('Кадр №', '${packet.sequence}'),
                          _TechRow('Uptime ESP32', '${packet.uptimeMs} мс'),
                          _TechRow(
                            'Последний кадр',
                            _fmtTime(packet.receivedAt),
                          ),
                        ],
                        _TechRow(
                          'Контрольная сумма',
                          frame.checksumOk ? 'OK' : 'ОШИБКА',
                          valueColor: frame.checksumOk
                              ? accentColor
                              : Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          BmDecoder.instance.toHex(frame.bytes),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: Colors.lightGreenAccent,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

// ================= Виджеты =================

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _ValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedRow extends StatelessWidget {
  final List<bool> lit;
  const _LedRow({required this.lit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < lit.length; i++)
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lit[i]
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.08),
                  boxShadow: lit[i]
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${i + 1}',
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TechRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _TechRow(this.title, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: secondaryText, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
