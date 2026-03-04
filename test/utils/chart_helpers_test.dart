// ABOUTME: Tests for chart formatting utilities.
// ABOUTME: Covers count abbreviation and date-to-x-value conversion.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/utils/chart_helpers.dart';

void main() {
  group('abbreviateCount', () {
    test('returns raw number for values under 1000', () {
      expect(abbreviateCount(0), '0');
      expect(abbreviateCount(999), '999');
    });

    test('abbreviates thousands with K suffix', () {
      expect(abbreviateCount(1000), '1,0K');
      expect(abbreviateCount(1500), '1,5K');
      expect(abbreviateCount(45000), '45,0K');
      expect(abbreviateCount(450000), '450,0K');
    });

    test('abbreviates millions with M suffix', () {
      expect(abbreviateCount(1000000), '1,0M');
      expect(abbreviateCount(1200000), '1,2M');
    });
  });

  group('dateToX', () {
    test('converts date to milliseconds since epoch', () {
      final d = DateTime(2025, 1, 1);
      expect(dateToX(d), d.millisecondsSinceEpoch.toDouble());
    });
  });

  group('formatDateLabel', () {
    test('formats date as MM/yy', () {
      expect(formatDateLabel(DateTime(2025, 3, 15)), '03/25');
      expect(formatDateLabel(DateTime(2024, 12, 1)), '12/24');
    });
  });
}
