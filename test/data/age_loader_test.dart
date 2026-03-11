// ABOUTME: Tests for AgeLoader snapshot assembly and resilient loading.
// ABOUTME: Verifies that partial fetch failures don't prevent loading available data.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/age_loader.dart';
import 'package:rpg_claude/data/data_source.dart';

const _csvContent =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n'
    '1;10;Barajevo;10 - 19;100\n'
    '1;10;Barajevo;20 - 29;200\n';

void main() {
  group('AgeLoader.loadAll', () {
    test('skips sources that fail and returns the rest', () async {
      final sources = [
        CsvSource(url: 'good1', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'bad', date: DateTime(2021, 1, 1)),
        CsvSource(url: 'good2', date: DateTime(2022, 1, 1)),
      ];
      final csvBytes = utf8.encode(_csvContent);

      final snapshots = await AgeLoader.loadAll(
        sources: sources,
        fetchBytes: (url) async {
          if (url == 'bad') throw Exception('404');
          return csvBytes;
        },
      );

      expect(snapshots.length, 2);
      expect(snapshots[0].date, DateTime(2020, 1, 1));
      expect(snapshots[1].date, DateTime(2022, 1, 1));
      expect(snapshots[0].records.length, 2);
      expect(snapshots[0].records[0].municipalityName, 'Barajevo');
      expect(snapshots[0].records[0].farmCount, 100);
    });

    test('throws when all sources fail', () async {
      final sources = [
        CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'bad2', date: DateTime(2021, 1, 1)),
      ];

      expect(
        () => AgeLoader.loadAll(
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

      final snapshots = await AgeLoader.loadAll(
        sources: sources,
        fetchBytes: (url) async => csvBytes,
      );

      expect(snapshots[0].date, DateTime(2020, 1, 1));
      expect(snapshots[1].date, DateTime(2021, 1, 1));
      expect(snapshots[2].date, DateTime(2022, 1, 1));
    });
  });
}
