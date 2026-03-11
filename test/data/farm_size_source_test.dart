// ABOUTME: Tests for FarmSizeSource — verifies the URL list is complete and ordered.
// ABOUTME: Does not make real HTTP calls; only tests the source list shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/farm_size_source.dart';

void main() {
  group('FarmSizeSource', () {
    test('provides exactly 9 CSV sources', () {
      expect(FarmSizeSource.sources.length, 9);
    });

    test('all sources have non-empty URLs and valid dates', () {
      for (final source in FarmSizeSource.sources) {
        expect(source.url, isNotEmpty);
        expect(source.date.year, greaterThanOrEqualTo(2018));
      }
    });

    test('sources are ordered oldest to newest', () {
      final dates = FarmSizeSource.sources.map((s) => s.date).toList();
      for (int i = 1; i < dates.length; i++) {
        expect(
          dates[i].isAfter(dates[i - 1]),
          isTrue,
          reason: 'Source $i is not after source ${i - 1}',
        );
      }
    });
  });
}
