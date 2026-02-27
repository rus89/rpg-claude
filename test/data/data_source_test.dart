// ABOUTME: Tests for DataSource — verifies the URL list is complete and fetch contracts.
// ABOUTME: Does not make real HTTP calls; only tests the source list shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/data_source.dart';

void main() {
  group('DataSource', () {
    test('provides exactly 12 CSV sources', () {
      expect(DataSource.sources.length, 12);
    });

    test('all sources have non-empty URLs and valid dates', () {
      for (final source in DataSource.sources) {
        expect(source.url, isNotEmpty);
        expect(source.date.year, greaterThanOrEqualTo(2018));
      }
    });

    test('sources are ordered oldest to newest', () {
      final dates = DataSource.sources.map((s) => s.date).toList();
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
