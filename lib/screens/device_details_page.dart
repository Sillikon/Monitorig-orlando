import 'package:flutter/material.dart';

import '../models/device_model.dart';
import '../services/bm_decoder.dart';
import '../services/mqtt_service.dart';

/// Экран конкретного BM-контроллера: расшифрованный кадр из ESP32.
class DeviceDetailsPage extends StatefulWidget {
  final DeviceModel device;
  const DeviceDetailsPage({super.key, required this.device});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  @override
  void initState() {
    super.initState();
    MqttService.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    MqttService.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  RawPacket? get _lastPacket {
    final packets = MqttService.instance.packetsByDevice[widget.device.deviceId];
    if (packets == null || packets.isEmpty) return null;
    return packets.last;
  }

  BmFrame? get _frame {
    final packet = _lastPacket;
    if (packet == null) return null;
    return BmDecoder.instance.decodeHex(packet.hex);
  }

  bool get _isOnline => MqttService.instance.deviceStatuses[widget.device.deviceId] == true;

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1018),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => MqttService.instance.refresh(),
          color: const Color(0xFF39D5A0),
          backgroundColor: const Color(0xFF151E2B),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (frame == null) ...[
                const _Placeholder(),
              ] else ...[
                _DisplayCard(
                  title: 'Режим работы',
                  text: frame.modeLabel ?? frame.modeText,
                  unit: '',
                  icon: Icons.settings_power,
                  iconColor: Colors.orangeAccent,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DisplayCard(
                        title: 'Часы программы',
                        text: frame.clockText,
                        unit: '',
                        icon: Icons.schedule,
                        iconColor: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DisplayCard(
                        title: 'Дни программы',
                        text: frame.daysText,
                        unit: '',
                        icon: Icons.calendar_today_outlined,
                        iconColor: const Color(0xFF39D5A0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LedLineCard(
                  title: 'Датчики температуры',
                  leds: frame.sensorLeds,
                  blinkMask: frame.blinkSensors,
                ),
                const SizedBox(height: 12),
                _LedLineCard(
                  title: 'Дни программы (линейка)',
                  leds: frame.dayLeds,
                  blinkMask: frame.blinkDays,
                ),
                const SizedBox(height: 12),
                _RelaysCard(frame: frame),
                const SizedBox(height: 12),
                _TechCard(packet: _lastPacket!, frame: frame),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF151E2B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BM Controller ${widget.device.deviceId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnline ? const Color(0xFF39D5A0) : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'В сети' : 'Не в сети',
                    style: const TextStyle(color: Color(0xFF8492A6), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF39D5A0).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.memory, color: Color(0xFF39D5A0), size: 20),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF151E2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.settings_input_component_outlined,
              color: Color(0xFF8492A6), size: 48),
          SizedBox(height: 12),
          Text(
            'Устройство пока не подключено',
            style: TextStyle(color: Color(0xFF8492A6), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Карточка одного цифрового индикатора (температура / часы / дни).
class _DisplayCard extends StatelessWidget {
  final String title;
  final String text;
  final String unit;
  final IconData icon;
  final Color iconColor;

  const _DisplayCard({
    required this.title,
    required this.text,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final display = text.isEmpty ? '—' : text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151E2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(color: Color(0xFF8492A6), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: display,
                    style: TextStyle(
                      color: display.contains('{')
                          ? Colors.orangeAccent
                          : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (unit.isNotEmpty && !display.contains('{'))
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                          color: Color(0xFF8492A6), fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Линейка из 8 светодиодов (датчики / дни).
class _LedLineCard extends StatelessWidget {
  final String title;
  final List<bool> leds;
  final int blinkMask;

  const _LedLineCard({
    required this.title,
    required this.leds,
    required this.blinkMask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151E2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Color(0xFF8492A6), fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (i) {
              final lit = leds[i];
              final blink = BmDecoder.instance.ledBlink(i, blinkMask);
              return Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lit
                          ? const Color(0xFF39D5A0)
                              .withOpacity(blink ? 0.35 : 1.0)
                          : const Color(0xFF2A3546),
                      boxShadow: lit
                          ? [
                              BoxShadow(
                                color: const Color(0xFF39D5A0)
                                    .withOpacity(blink ? 0.2 : 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${i + 1}',
                      style: const TextStyle(
                          color: Color(0xFF8492A6), fontSize: 10)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Состояние агрегатов (байт 16).
class _RelaysCard extends StatelessWidget {
  final BmFrame frame;
  const _RelaysCard({required this.frame});

  @override
  Widget build(BuildContext context) {
    final relays = BmDecoder.instance.relays(frame.relaysByte);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151E2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Состояние агрегатов',
              style: TextStyle(color: Color(0xFF8492A6), fontSize: 13)),
          const SizedBox(height: 8),
          ...relays.map((r) {
            final alarmActive = r.isAlarm && r.on;
            final ok = r.isAlarm && !r.on;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    r.isAlarm
                        ? (alarmActive ? Icons.warning_amber : Icons.check_circle_outline)
                        : Icons.power_settings_new,
                    size: 18,
                    color: alarmActive
                        ? Colors.redAccent
                        : (r.on ? const Color(0xFF39D5A0) : const Color(0xFF8492A6)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.name,
                      style: TextStyle(
                        color: alarmActive ? Colors.redAccent : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (r.isAlarm)
                    _StateChip(
                      text: alarmActive ? 'ТРЕВОГА' : 'НОРМА',
                      color: alarmActive ? Colors.redAccent : const Color(0xFF39D5A0),
                    )
                  else
                    _StateChip(
                      text: r.on ? 'ВКЛ' : 'ВЫКЛ',
                      color: r.on ? const Color(0xFF39D5A0) : const Color(0xFF8492A6),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StateChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  final RawPacket packet;
  final BmFrame frame;
  const _TechCard({required this.packet, required this.frame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151E2B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Технические данные',
              style: TextStyle(color: Color(0xFF8492A6), fontSize: 13)),
          const SizedBox(height: 12),
          _TechRow(label: 'Режим (сырой код)', value: frame.modeText),
          _TechRow(label: 'Кадр №', value: '${packet.sequence}'),
          _TechRow(label: 'Uptime ESP32', value: '${packet.uptimeMs} мс'),
          _TechRow(
            label: 'Последний кадр',
            value: _fmtTime(packet.receivedAt),
          ),
          _TechRow(
            label: 'Контрольная сумма',
            value: frame.checksumOk ? 'OK' : 'ОШИБКА',
            valueColor: frame.checksumOk ? const Color(0xFF39D5A0) : Colors.redAccent,
          ),
          const SizedBox(height: 8),
          Center(
            child: SelectableText(
              packet.hex,
              style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}

class _TechRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TechRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8492A6), fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
