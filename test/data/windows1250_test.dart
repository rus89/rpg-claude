// ABOUTME: Tests for Windows-1250 byte-to-String decoder.
// ABOUTME: Verifies correct decoding of Serbian diacritics that differ from Latin-1.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/windows1250.dart';

void main() {
  group('windows1250Decode', () {
    test('decodes ASCII bytes unchanged', () {
      final bytes = [0x48, 0x65, 0x6C, 0x6C, 0x6F]; // "Hello"
      expect(windows1250Decode(bytes), 'Hello');
    });

    test('decodes Serbian diacritics in 0x80-0x9F range', () {
      // Š=0x8A, š=0x9A, Ž=0x8E, ž=0x9E
      expect(windows1250Decode([0x8A]), 'Š');
      expect(windows1250Decode([0x9A]), 'š');
      expect(windows1250Decode([0x8E]), 'Ž');
      expect(windows1250Decode([0x9E]), 'ž');
    });

    test('decodes Serbian diacritics in 0xA0-0xFF range', () {
      // Đ=0xD0, đ=0xF0, Č=0xC8, č=0xE8... wait, need to check
      // In Windows-1250: Ć=0xC6, ć=0xE6, Č=0xC8, č=0xE8, Đ=0xD0, đ=0xF0
      expect(windows1250Decode([0xC6]), 'Ć');
      expect(windows1250Decode([0xE6]), 'ć');
      expect(windows1250Decode([0xC8]), 'Č');
      expect(windows1250Decode([0xE8]), 'č');
      expect(windows1250Decode([0xD0]), 'Đ');
      expect(windows1250Decode([0xF0]), 'đ');
    });

    test('decodes full municipality name "Šabac"', () {
      // Š=0x8A, a=0x61, b=0x62, a=0x61, c=0x63
      final bytes = [0x8A, 0x61, 0x62, 0x61, 0x63];
      expect(windows1250Decode(bytes), 'Šabac');
    });

    test('decodes full municipality name "Čačak"', () {
      // Č=0xC8, a=0x61, č=0xE8, a=0x61, k=0x6B
      final bytes = [0xC8, 0x61, 0xE8, 0x61, 0x6B];
      expect(windows1250Decode(bytes), 'Čačak');
    });

    test('decodes full municipality name "Žitorađa"', () {
      // Ž=0x8E, i=0x69, t=0x74, o=0x6F, r=0x72, a=0x61, đ=0xF0, a=0x61
      final bytes = [0x8E, 0x69, 0x74, 0x6F, 0x72, 0x61, 0xF0, 0x61];
      expect(windows1250Decode(bytes), 'Žitorađa');
    });
  });
}
