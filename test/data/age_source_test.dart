// ABOUTME: Tests for AgeSource — verifies the URL list is complete and ordered.
// ABOUTME: Does not make real HTTP calls; only tests the source list shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/age_source.dart';

void main() {
  group('AgeSource', () {
    test('provides exactly 11 CSV sources', () {
      expect(AgeSource.sources.length, 11);
    });

    test('all sources have non-empty URLs and valid dates', () {
      for (final source in AgeSource.sources) {
        expect(source.url, isNotEmpty);
        expect(source.date.year, greaterThanOrEqualTo(2018));
      }
    });

    test('sources are ordered oldest to newest', () {
      final dates = AgeSource.sources.map((s) => s.date).toList();
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
