import 'package:flutter/foundation.dart';

/// Единый символ индикатора (одно знакоместо).
class BmDigit {
  /// Символ для показа: '0'..'9', '.', или набор сегментов вида "{AEFG}" для
  /// нестандартных комбинаций, или null если знакоместо пустое (0xFF).
  final String? char;

  /// Сегменты, которые реально горят (A..G + H = точка).
  final Set<String> segments;

  /// Точка (сегмент H) горит.
  final bool dot;

  /// Сегмент мигает (по маске мигания).
  final bool blinking;

  const BmDigit({
    required this.char,
    required this.segments,
    required this.dot,
    required this.blinking,
  });

  bool get blank => char == null && segments.isEmpty && !dot;
}

/// Расшифрованный 19-байтный кадр BM V57x2.
///
/// Раскладка (подтверждена по руководству + живым кадрам,
/// стартовых байт в потоке нет):
///   [0,1]   знакоместа 1,2   — индикатор температуры (слева)
///   [2..5]  знакоместа 7..10 — индикатор «Days of Program» (справа)
///   [6]     линейка датчиков температуры (0 = светодиод зажжён)
///   [7]     линейка дней программы       (0 = светодиод зажжён)
///   [8]     маска мигания сегментов знакоместа 1
///   [9]     маска мигания сегментов знакоместа 2
///   [10]    маска мигания светодиодов датчиков
///   [11]    маска мигания светодиодов дней
///   [12..15] знакоместа 3..6 — индикатор «Clock of Program» (центр)
///   [16]    байт агрегатов (1 = выключен, 0 = включен)
///   [17,18] контрольная сумма (мл., ст.) — сумма байт 0..16
class BmFrame {
  /// Знакоместа 1,2 (температура слева).
  final List<BmDigit> tempDigits;

  /// Знакоместа 3..6 (часы программы, центр).
  final List<BmDigit> clockDigits;

  /// Знакоместа 7..10 (дни программы, справа).
  final List<BmDigit> dayDigits;

  /// Линейка датчиков: true = светодиод зажжён. Индекс 0 = датчик 1.
  final List<bool> sensorLeds;

  /// Линейка дней: true = светодиод зажжён. Индекс 0 = день 1.
  final List<bool> dayLeds;

  /// Маска мигания светодиодов датчиков (бит=1 → мигает).
  final int blinkSensors;

  /// Маска мигания светодиодов дней (бит=1 → мигает).
  final int blinkDays;

  /// Байт агрегатов (сырой).
  final int relaysByte;

  /// Контрольная сумма сошлась.
  final bool checksumOk;

  const BmFrame({
    required this.tempDigits,
    required this.clockDigits,
    required this.dayDigits,
    required this.sensorLeds,
    required this.dayLeds,
    required this.blinkSensors,
    required this.blinkDays,
    required this.relaysByte,
    required this.checksumOk,
  });

  /// Текст индикатора режима (знакоместа 1,2): "Pr", "GS" и т.п.
  String get modeText {
    final raw = tempDigits
        .map((d) => d.char ?? (d.segments.isEmpty ? '' : '{${d.segments.join()}}'))
        .join();
    return raw.trim();
  }

  /// Режим в человекочитаемом виде, напр. «Газация».
  String? get modeLabel => BmDecoder._modeTable[modeText];

  /// Текст индикатора режима (сырой), напр. "0.5" или "{ACDEF}·5.".
  String get tempText => _digitsToText(tempDigits);

  /// Текст индикатора часов программы.
  String get clockText => _digitsToText(clockDigits);

  /// Текст индикатора дней программы, напр. "16.7".
  String get daysText => _digitsToText(dayDigits);

  static String _digitsToText(List<BmDigit> digits) {
    final buf = StringBuffer();
    for (final d in digits) {
      if (d.blank) {
        buf.write(' ');
      } else if (d.char != null) {
        buf.write(d.char);
        if (d.dot) buf.write('.');
      } else {
        buf.write('{${d.segments.join()}}');
        if (d.dot) buf.write('.');
      }
    }
    return buf.toString().trim();
  }
}

/// Состояние одного агрегата.
class BmRelay {
  final String name;
  final bool on;

  /// Для тревоги: true = тревоги нет (бит=1), false = тревога активна (бит=0).
  final bool isAlarm;

  const BmRelay(this.name, this.on, {this.isAlarm = false});
}

class BmDecoder {
  BmDecoder._();
  static final BmDecoder instance = BmDecoder._();

  static const int frameLength = 19;
  static const int relaysIndex = 16;

  /// Порядок бит в байте агрегатов (по руководству, бит 7 — старший слева):
  /// бит7 — Блокировка дверей, бит6 — Газ, бит5 — Охлаждение,
  /// бит4 — Вентиляция, бит3 — Вентилятор воздухоохладителя,
  /// бит2 — Нагрев, бит1 — резерв, бит0 — Тревога.
  static const List<String> relayNames = [
    'Нагрев',
    'Вентилятор воздухоохладителя',
    'Вентиляция',
    'Охлаждение',
    'Газ',
    'Блокировка дверей',
  ];

  /// Калиброванная таблица сегментов: код → символ.
  /// Код = биты A..G (бит0=A … бит6=G), точка (H, бит7) обрабатывается отдельно.
  /// Подтверждена кадром-примером из руководства и живыми кадрами.
  static const Map<int, String> _segmentTable = {
    0x3F: '0',
    0x06: '1',
    0x5B: '2',
    0x4F: '3',
    0x66: '4',
    0x6D: '5',
    0x7D: '6',
    0x07: '7',
    0x7F: '8',
    0x6F: '9',
    0x40: '-', // только средний сегмент
    // Буквы (для индикатора режима и нестандартных символов)
    0x77: 'A', // A,B,C,E,F,G
    0x7C: 'b', // C,D,E,F,G
    0x39: 'C', // A,D,E,F
    0x5E: 'd', // B,C,D,E,G
    0x79: 'E', // A,D,E,F,G
    0x71: 'F', // A,E,F,G
    0x3D: 'G', // A,C,D,E,F
    0x76: 'H', // B,C,E,F,G
    0x38: 'L', // D,E,F
    0x54: 'n', // C,E,G
    0x5C: 'o', // C,D,E,G
    0x73: 'P', // A,B,E,F,G
    0x50: 'r', // E,G
    0x78: 't', // D,E,F,G
    0x3E: 'U', // B,C,D,E,F
    0x6E: 'Y', // B,C,D,F,G
  };

  /// Распознавание режима по первым двум знакоместам (индикатор режима).
  static const Map<String, String> _modeTable = {
    'GS': 'Газация',
    'G5': 'Газация', // S и 5 неотличимы на 7-сегментнике
    'PR': 'Программа',
    'Pr': 'Программа',
    'ST': 'Стоп',
    '5T': 'Стоп',
    'ON': 'Работа',
    '0N': 'Работа',
    'AL': 'Авария',
  };

  /// Проверка контрольной суммы: сумма байт 0..16 == байт17 | байт18<<8.
  bool verifyChecksum(List<int> frame) {
    if (frame.length < frameLength) return false;
    int sum = 0;
    for (var i = 0; i < frameLength - 2; i++) {
      sum += frame[i];
    }
    final crc = frame[frameLength - 2] | (frame[frameLength - 1] << 8);
    return sum == crc;
  }

  BmDigit _decodeDigit(int byte, int blinkMask) {
    const segByBit = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final segments = <String>{};
    var code = 0;
    for (var i = 0; i < 7; i++) {
      final bit = (byte >> i) & 1;
      if (bit == 0) {
        segments.add(segByBit[i]);
        code |= 1 << i;
      }
    }
    final dot = (byte & 0x80) == 0;
    final anyBlink = segments.any((s) {
      final idx = segByBit.indexOf(s);
      return ((blinkMask >> idx) & 1) == 1;
    }) ||
        (dot && ((blinkMask & 0x80) != 0));

    if (byte == 0xFF) {
      return BmDigit(char: null, segments: const {}, dot: false, blinking: anyBlink);
    }
    final known = _segmentTable[code];
    return BmDigit(
      char: known,
      segments: segments,
      dot: dot,
      blinking: anyBlink,
    );
  }

  List<bool> _decodeLeds(int byte, int blinkMask) {
    // Бит 7 = светодиод 8 … бит 0 = светодиод 1. 0 = зажжён.
    return List.generate(8, (i) {
      final bit = 7 - i;
      return ((byte >> bit) & 1) == 0;
    });
  }

  bool _ledBlink(int index, int blinkMask) {
    final bit = 7 - index;
    return ((blinkMask >> bit) & 1) == 1;
  }

  /// Декодирует 19-байтный кадр.
  BmFrame decode(List<int> frame) {
    assert(frame.length >= frameLength);
    return BmFrame(
      tempDigits: [
        _decodeDigit(frame[0], frame[8]),
        _decodeDigit(frame[1], frame[9]),
      ],
      dayDigits: [
        _decodeDigit(frame[2], 0),
        _decodeDigit(frame[3], 0),
        _decodeDigit(frame[4], 0),
        _decodeDigit(frame[5], 0),
      ],
      clockDigits: [
        _decodeDigit(frame[12], 0),
        _decodeDigit(frame[13], 0),
        _decodeDigit(frame[14], 0),
        _decodeDigit(frame[15], 0),
      ],
      sensorLeds: _decodeLeds(frame[6], frame[10]),
      dayLeds: _decodeLeds(frame[7], frame[11]),
      blinkSensors: frame[10],
      blinkDays: frame[11],
      relaysByte: frame[relaysIndex],
      checksumOk: verifyChecksum(frame),
    );
  }

  /// Декодирует HEX-строку из 38 символов (19 байт).
  BmFrame? decodeHex(String hex) {
    if (hex.length < 38) return null;
    final bytes = <int>[];
    for (var i = 0; i < 38; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return decode(bytes);
  }

  /// Список агрегатов: (название, включён).
  /// ВНИМАНИЕ: в прошивке V57x2 полярность ИНВЕРТИРОВАНА относительно
  /// руководства — 1 = ВКЛ, 0 = ВЫКЛ (подтверждено: газация при бите=1).
  /// Исключение — Тревога: 0 = тревога активна, 1 = тревоги нет.
  /// Биты: 2 Нагрев, 3 Вент.возд., 4 Вентиляция, 5 Охлаждение, 6 Газ,
  /// 7 Блок.дверей, 0 Тревога.
  List<BmRelay> relays(int relaysByte) {
    bool on(int bit) => ((relaysByte >> bit) & 1) == 1;
    return [
      BmRelay('Нагрев', on(2)),
      BmRelay('Вентилятор воздухоохладителя', on(3)),
      BmRelay('Вентиляция', on(4)),
      BmRelay('Охлаждение', on(5)),
      BmRelay('Газ', on(6)),
      BmRelay('Блокировка дверей', on(7)),
      // Тревога (как в руководстве): бит=0 — тревога активна, бит=1 — нет.
      BmRelay('Тревога', !on(0), isAlarm: true),
    ];
  }

  bool ledBlink(int index, int blinkMask) => _ledBlink(index, blinkMask);

  /// HEX кадра для отладки.
  String toHex(List<int> frame) =>
      frame.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
}
