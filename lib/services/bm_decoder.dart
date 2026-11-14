/// Декодер кадров контроллера Bletting Manager (BM V57x2).
///
/// Формат кадра (19 байт, по руководству пользователя):
///   байты 0..1   — знакоместа 1..2 (двухразрядный индикатор режима)
///   байты 2..9   — знакоместа 3..10 (4 цифры часов программы + 4 цифры
///                  основного значения)
///   байт  10     — линейка светодиодов датчиков температуры (1=погашен)
///   байт  11     — линейка светодиодов дней программы (1=погашен)
///   байты 12..15 — маски мигающих сегментов знакомест 1..4
///   байт  16     — состояние агрегатов (1=выключен, 0=включен)
///   байты 17..18 — контрольная сумма (младший, старший байт;
///                  арифметическая сумма байт 0..16)
///
/// ВНИМАНИЕ: порядок бит сегментов и некоторые границы полей
/// восстановлены из распознанного текста руководства и калибруются
/// по реальным кадрам. Все сомнительные места собраны в константах
/// ниже — при расхождении с дисплеем меняем только их.
library;

/// Одна расшифрованная цифра семисегментного индикатора.
class BmDigit {
  /// Исходный байт знакоместа.
  final int raw;

  /// Символ ('0'-'9', 'A'-'F', пробел) или null, если комбинация
  /// сегментов не распознана.
  final String? char;

  /// Зажжён ли символ вообще (все сегменты погашены).
  final bool blank;

  /// Мигающие сегменты (по маске из кадра).
  final bool blinking;

  const BmDigit({
    required this.raw,
    required this.char,
    required this.blank,
    this.blinking = false,
  });
}

/// Состояние одного выхода (агрегата) камеры.
class BmRelay {
  final String name;
  final bool on;
  const BmRelay(this.name, this.on);
}

/// Полностью расшифрованный кадр.
class BmFrame {
  final List<int> bytes;

  /// Режим работы: «On», «GS», «Pr», «St» или null.
  final String? mode;

  /// 4 цифры часов программы (обычно HH.MM).
  final List<BmDigit> clockDigits;

  /// 4 цифры основного значения (обычно температура XX.X).
  final List<BmDigit> valueDigits;

  /// 8 светодиодов линейки датчиков (true = горит).
  final List<bool> sensorLeds;

  /// 8 светодиодов линейки дней программы (true = горит).
  final List<bool> dayLeds;

  /// Состояние агрегатов.
  final List<BmRelay> relays;

  /// Контрольная сумма сошлась.
  final bool checksumOk;

  const BmFrame({
    required this.bytes,
    required this.mode,
    required this.clockDigits,
    required this.valueDigits,
    required this.sensorLeds,
    required this.dayLeds,
    required this.relays,
    required this.checksumOk,
  });

  /// Часы программы строкой, например «03.45».
  String get clockText => _digitsToText(clockDigits);

  /// Основное значение строкой, например «20.0».
  String get valueText => _digitsToText(valueDigits);

  static String _digitsToText(List<BmDigit> digits) {
    final buf = StringBuffer();
    for (final d in digits) {
      buf.write(d.char ?? (d.blank ? ' ' : '?'));
    }
    return buf.toString().trim();
  }
}

class BmDecoder {
  BmDecoder._();
  static final BmDecoder instance = BmDecoder._();

  // ================== КАЛИБРОВОЧНЫЕ КОНСТАНТЫ ==================

  /// Привязка бит байта знакоместа к сегментам индикатора.
  /// Индекс в списке = номер бита (0 = младший).
  static const List<String> segmentByBit = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
  ];

  /// true = сегмент погашен при бите 1 (по руководству).
  static const bool inactiveHigh = true;

  /// Индексы полей в кадре.
  static const int modeByte1 = 0;
  static const int modeByte2 = 1;
  static const int clockStart = 2; // 4 байта
  static const int valueStart = 6; // 4 байта
  static const int sensorLedByte = 10;
  static const int dayLedByte = 11;
  static const int blinkStart = 12; // маски мигающих сегментов
  static const int relaysByte = 16;

  /// Агрегаты: (название, номер бита в байте 16, инверсия).
  /// По руководству: 1 = выключен, 0 = включен.
  static const List<(String, int)> relayBits = [
    ('Нагрев', 0),
    ('Вентилятор воздухоохладителя', 1),
    ('Вентиляция', 2),
    ('Охлаждение', 3),
    ('Газ', 4),
    ('Блокировка дверей', 5),
    ('Тревога', 6),
  ];

  /// Таблица сегментов (A B C D E F G) -> символ.
  /// 1 = сегмент горит. Порядок сегментов — kSegmentOrder.
  static const Map<int, String> _segmentTable = {
    0x3F: '0', 0x06: '1', 0x5B: '2', 0x4F: '3',
    0x66: '4', 0x6D: '5', 0x7D: '6', 0x07: '7',
    0x7F: '8', 0x6F: '9', 0x77: 'A', 0x7C: 'b',
    0x39: 'C', 0x5E: 'd', 0x79: 'E', 0x71: 'F',
  };

  /// Маска горящих сегментов для режимов (по двум байтам режима).
  static const Map<String, String> _modeTable = {
    'On': 'On',
    'GS': 'GS',
    'Pr': 'Pr',
    'St': 'St',
  };

  // ================== РАСШИФРОВКА ==================

  bool verifyChecksum(List<int> frame) {
    if (frame.length != 19) return false;
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      sum += frame[i];
    }
    final crc = frame[17] | (frame[18] << 8);
    return sum == crc;
  }

  /// Расшифровать кадр из 19 байт (список int).
  BmFrame decode(List<int> frame) {
    final ok = verifyChecksum(frame);

    BmDigit digit(int byteIndex) {
      final raw = frame[byteIndex];
      final segs = _activeSegments(raw);
      final blank = segs.isEmpty;
      final char = blank ? null : _segmentTable[_mask(segs)];
      return BmDigit(raw: raw, char: char, blank: blank);
    }

    final clockDigits = [
      for (var i = 0; i < 4; i++) digit(clockStart + i),
    ];
    final valueDigits = [
      for (var i = 0; i < 4; i++) digit(valueStart + i),
    ];

    final modeChars = [
      _segmentTable[_mask(_activeSegments(frame[modeByte1]))],
      _segmentTable[_mask(_activeSegments(frame[modeByte2]))],
    ];
    final modeText = modeChars.join();
    final mode = _modeTable[modeText] ??
        ((modeChars.any((c) => c != null)) ? modeText : null);

    final sensorLeds = [
      for (var i = 0; i < 8; i++)
        _ledOn(frame[sensorLedByte], i),
    ];
    final dayLeds = [
      for (var i = 0; i < 8; i++) _ledOn(frame[dayLedByte], i),
    ];

    final relays = [
      for (final (name, bit) in relayBits)
        BmRelay(name, !_bit(frame[relaysByte], bit)),
    ];

    return BmFrame(
      bytes: List.unmodifiable(frame),
      mode: mode,
      clockDigits: clockDigits,
      valueDigits: valueDigits,
      sensorLeds: sensorLeds,
      dayLeds: dayLeds,
      relays: relays,
      checksumOk: ok,
    );
  }

  /// Расшифровать из HEX-строки (как приходит в MQTT «hex»).
  BmFrame? decodeHex(String hex) {
    final clean = hex.replaceAll(' ', '');
    if (clean.length != 38) return null;
    final bytes = <int>[];
    for (var i = 0; i < 38; i += 2) {
      bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return decode(bytes);
  }

  // ================== ВНУТРЕННЕЕ ==================

  /// Список горящих сегментов байта знакоместа.
  Set<String> _activeSegments(int byte) {
    final result = <String>{};
    for (var bit = 0; bit < 8; bit++) {
      final isSet = (byte & (1 << bit)) != 0;
      final lit = inactiveHigh ? !isSet : isSet;
      if (lit) result.add(segmentByBit[bit]);
    }
    return result;
  }

  /// Маска сегментов A..G для таблицы символов.
  int _mask(Set<String> segs) {
    var mask = 0;
    const order = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    for (var i = 0; i < order.length; i++) {
      if (segs.contains(order[i])) mask |= 1 << i;
    }
    return mask;
  }

  int _bitForSegment(String seg) => segmentByBit.indexOf(seg);

  bool _bit(int byte, int bit) => (byte & (1 << bit)) != 0;

  /// Светодиод линейки: по руководству 1 = погашен.
  bool _ledOn(int byte, int index) => !_bit(byte, index);

  /// HEX-строка кадра для отладки.
  String toHex(List<int> bytes) {
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buf.toString();
  }
}
