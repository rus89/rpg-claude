// ABOUTME: Tests for AgeRecord model construction.
// ABOUTME: Verifies all fields are stored correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/age_bracket.dart';
import 'package:rpg_claude/data/models/age_record.dart';

void main() {
  group('AgeRecord', () {
    test('stores all fields correctly', () {
      const record = AgeRecord(
        regionCode: '1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        ageBracket: AgeBracket.age30to39,
        farmCount: 42,
      );
      expect(record.regionCode, '1');
      expect(record.municipalityCode, '10');
      expect(record.municipalityName, 'Barajevo');
      expect(record.ageBracket, AgeBracket.age30to39);
      expect(record.farmCount, 42);
    });
  });
}
