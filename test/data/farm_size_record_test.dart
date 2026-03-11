// ABOUTME: Tests for FarmSizeRecord computed properties.
// ABOUTME: Verifies totalFarms, totalArea, and averageSize calculations.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/farm_size_record.dart';

void main() {
  group('FarmSizeRecord', () {
    const record = FarmSizeRecord(
      regionCode: '1',
      regionName: 'GRAD BEOGRAD',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      countUpTo5: 100,
      areaUpTo5: 200.0,
      count5to20: 50,
      area5to20: 500.0,
      count20to100: 20,
      area20to100: 1000.0,
      countOver100: 5,
      areaOver100: 800.0,
    );

    test('totalFarms sums all count brackets', () {
      expect(record.totalFarms, 175);
    });

    test('totalArea sums all area brackets', () {
      expect(record.totalArea, 2500.0);
    });

    test('averageSize divides totalArea by totalFarms', () {
      expect(record.averageSize, closeTo(2500.0 / 175, 0.0001));
    });

    test('averageSize returns 0 when totalFarms is 0', () {
      const empty = FarmSizeRecord(
        regionCode: '',
        regionName: '',
        municipalityCode: '',
        municipalityName: '',
        countUpTo5: 0,
        areaUpTo5: 0,
        count5to20: 0,
        area5to20: 0,
        count20to100: 0,
        area20to100: 0,
        countOver100: 0,
        areaOver100: 0,
      );
      expect(empty.averageSize, 0);
    });
  });
}
