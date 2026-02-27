// ABOUTME: Tests for DataLoader snapshot assembly and resilient loading.
// ABOUTME: Verifies that partial fetch failures don't prevent loading available data.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/data_loader.dart';
import 'package:rpg_claude/data/data_source.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';

const _csvContent =
    'sifra_regiona;region;sifra_opstine;opstina;organizacioni_oblik;broj_ukupno_registrovanih;broj_aktivnih\n'
    '1;GRAD BEOGRAD;10;Barajevo;1;100;90\n';

void main() {
  group('DataLoader.buildSnapshot', () {
    test('combines date and records into a Snapshot', () {
      final date = DateTime(2025, 12, 31);
      const records = [
        Record(
          regionCode: '1',
          regionName: 'GRAD BEOGRAD',
          municipalityCode: '10',
          municipalityName: 'Barajevo',
          orgForm: OrgForm.familyFarm,
          totalRegistered: 100,
          activeHoldings: 90,
        ),
      ];
      final snapshot = DataLoader.buildSnapshot(date, records);
      expect(snapshot.date, date);
      expect(snapshot.records.length, 1);
    });
  });

  group('DataLoader.loadAll resilience', () {
    test('skips sources that fail and returns the rest', () async {
      final sources = [
        CsvSource(url: 'good1', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'bad', date: DateTime(2021, 1, 1)),
        CsvSource(url: 'good2', date: DateTime(2022, 1, 1)),
      ];
      final csvBytes = utf8.encode(_csvContent);

      final snapshots = await DataLoader.loadAll(
        sources: sources,
        fetchBytes: (url) async {
          if (url == 'bad') throw Exception('404');
          return csvBytes;
        },
      );

      expect(snapshots.length, 2);
      expect(snapshots[0].date, DateTime(2020, 1, 1));
      expect(snapshots[1].date, DateTime(2022, 1, 1));
    });

    test('throws when all sources fail', () async {
      final sources = [
        CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
        CsvSource(url: 'bad2', date: DateTime(2021, 1, 1)),
      ];

      expect(
        () => DataLoader.loadAll(
          sources: sources,
          fetchBytes: (url) async => throw Exception('fail'),
        ),
        throwsException,
      );
    });
  });
}
