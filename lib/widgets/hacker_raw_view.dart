import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/bm_decoder.dart';
import '../services/mqtt_service.dart';

/// «Хакерский» терминал: поток свежих кадров в стиле матрицы —
/// тёмный фон, светящийся моноширинный HEX, новые строки
/// появляются снизу и уходят вверх.
class HackerRawView extends StatefulWidget {
  /// ID устройства, чей поток показываем.
  final String deviceId;

  /// Режим отображения: сырой HEX или расшифровка.
  final bool decodedMode;

  const HackerRawView({
    super.key,
    required this.deviceId,
    this.decodedMode = false,
  });

  @override
  State<HackerRawView> createState() => _HackerRawViewState();
}

class _HackerRawViewState extends State<HackerRawView> {
  static const int _maxLines = 9;

  final List<_TerminalLine> _lines = [];
  final Random _random = Random();
  Timer? _cursorTimer;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();
    MqttService.instance.addListener(_onData);
    _cursorTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() => _cursorVisible = !_cursorVisible),
    );
    _rebuild();
  }

  @override
  void dispose() {
    MqttService.instance.removeListener(_onData);
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HackerRawView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId ||
        oldWidget.decodedMode != widget.decodedMode) {
      _rebuild();
    }
  }

  void _onData() => _rebuild();

  void _rebuild() {
    final packets =
        MqttService.instance.packetsByDevice[widget.deviceId] ?? [];
    final take = packets.length > _maxLines
        ? packets.sublist(packets.length - _maxLines)
        : packets;

    setState(() {
      _lines
        ..clear()
        ..addAll([
          for (final p in take)
            _TerminalLine(
              hex: p.hex,
              seq: p.sequence,
              time: p.receivedAt,
              jitter: _random.nextDouble(),
            ),
        ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,
      decoration: BoxDecoration(
        color: const Color(0xFF040A06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Строки терминала
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
              itemCount: _lines.length,
              itemBuilder: (_, i) =>
                  _buildLine(_lines[i], i == _lines.length - 1),
            ),
          ),

          // Строка статуса снизу
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF040A06).withValues(alpha: 0.92),
                border: Border(
                  top: BorderSide(
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal,
                    size: 13,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'bm://stream/${widget.deviceId}'
                    '${widget.decodedMode ? ' · decoded' : ''}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: accentColor.withValues(alpha: 0.75),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_lines.length} кадров',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(_TerminalLine line, bool isLast) {
    final base = widget.decodedMode ? _decodedText(line) : line.hex;
    final glow = isLast ? 1.0 : 0.35 + line.jitter * 0.3;

    final parts = base.length > 40
        ? '${base.substring(0, 40)}…'
        : base;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(
        '> $parts',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.35,
          color: Color.lerp(
            const Color(0xFF0E3B24),
            const Color(0xFF39FF9A),
            glow,
          ),
          shadows: isLast
              ? const [
                  Shadow(
                    color: Color(0x6639FF9A),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  String _decodedText(_TerminalLine line) {
    final frame = BmDecoder.instance.decodeHex(line.hex);
    if (frame == null) return line.hex;
    final mode = (frame.modeLabel ?? frame.modeText).padLeft(6);
    final clock = frame.clockText.padLeft(6);
    final days = frame.daysText.padLeft(6);
    final relaysOn = BmDecoder.instance
        .relays(frame.relaysByte)
        .where((r) => r.on)
        .map((r) => r.name)
        .join(',');
    return '$mode | clk=$clock | day=$days | $relaysOn';
  }
}

class _TerminalLine {
  final String hex;
  final int seq;
  final DateTime time;
  final double jitter;

  const _TerminalLine({
    required this.hex,
    required this.seq,
    required this.time,
    required this.jitter,
  });
}
