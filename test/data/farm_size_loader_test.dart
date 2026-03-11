// ABOUTME: Tests for FarmSizeLoader snapshot assembly and resilient loading.
// ABOUTME: Verifies that partial fetch failures don't prevent loading available data.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/data_source.dart';
import 'package:rpg_claude/data/farm_size_loader.dart';

const _csvContent =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;50;500,75;20;1000,25;5;800,0\n';

void main() {
  group('FarmSizeLoader.loadAll', () {
    test('skips sources that fail and returns the rest', () async {
      final sources = [
        CsvSource(url: 'good1', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'bad', date: DateTime(2021, 1, 1)),
        CsvSource(url: 'good2', date: DateTime(2022, 1, 1)),
      ];
      final csvBytes = utf8.encode(_csvContent);

      final snapshots = await FarmSizeLoader.loadAll(
        sources: sources,
        fetchBytes: (url) async {
          if (url == 'bad') throw Exception('404');
          return csvBytes;
        },
      );

      expect(snapshots.length, 2);
      expect(snapshots[0].date, DateTime(2020, 1, 1));
      expect(snapshots[1].date, DateTime(2022, 1, 1));
      expect(snapshots[0].records.length, 1);
      expect(snapshots[0].records[0].municipalityName, 'Barajevo');
      expect(snapshots[0].records[0].countUpTo5, 100);
      expect(snapshots[0].records[0].areaUpTo5, closeTo(200.5, 0.001));
    });

    test('throws when all sources fail', () async {
      final sources = [
        CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'bad2', date: DateTime(2021, 1, 1)),
      ];

      expect(
        () => FarmSizeLoader.loadAll(
          sources: sources,
          fetchBytes: (url) async => throw Exception('fail'),
        ),
        throwsException,
      );
    });

    test('results sorted by date', () async {
      final sources = [
        CsvSource(url: 'c', date: DateTime(2022, 1, 1)),
        CsvSource(url: 'a', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'b', date: DateTime(2021, 1, 1)),
      ];
      final csvBytes = utf8.encode(_csvContent);

      final snapshots = await FarmSizeLoader.loadAll(
        sources: sources,
        fetchBytes: (url) async => csvBytes,
      );

      expect(snapshots[0].date, DateTime(2020, 1, 1));
      expect(snapshots[1].date, DateTime(2021, 1, 1));
      expect(snapshots[2].date, DateTime(2022, 1, 1));
    });
  });
}
