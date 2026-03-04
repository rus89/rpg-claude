// ABOUTME: Tests for CSV parsing logic.
// ABOUTME: Covers header-based column mapping, encoding fallback, and malformed row skipping.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/csv_parser.dart';
import 'package:rpg_claude/data/models/org_form.dart';

void main() {
  group('CsvParser.parse', () {
    test('parses valid semicolon-delimited CSV bytes into records', () {
      const content =
          'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;1417;1385\n'
          '1;GRAD BEOGRAD;10;Barajevo;2;Preduzeca;8;8\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 2);
      expect(records[0].municipalityName, 'Barajevo');
      expect(records[0].orgForm, OrgForm.familyFarm);
      expect(records[0].totalRegistered, 1417);
      expect(records[0].activeHoldings, 1385);
    });

    test('skips rows with non-integer count fields', () {
      const content =
          'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;bad;1385\n'
          '1;GRAD BEOGRAD;10;Barajevo;2;Preduzeca;8;8\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
    });

    test('skips rows with unknown org form code', () {
      const content =
          'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;99;Unknown;10;10\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 0);
    });

    test('parses CSV with Windows-style \\r\\n line endings', () {
      const content =
          'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\r\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;1417;1385\r\n'
          '1;GRAD BEOGRAD;10;Barajevo;2;Preduzeca;8;8\r\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 2);
      expect(records[0].totalRegistered, 1417);
      expect(records[0].activeHoldings, 1385);
    });

    test('decodes Windows-1250 encoded CSV with Serbian diacritics', () {
      // Windows-1250 bytes: Š=0x8A, č=0xE8, ž=0x9E, đ=0xF0, ć=0xE6
      // Row: 1;REGION;10;Šabac;1;Label;100;90
      final bytes = <int>[
        // Header (ASCII)
        ...('Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n')
            .codeUnits,
        // Data row with W-1250 Š (0x8A) in municipality name
        0x31, 0x3B, // 1;
        0x52, 0x45, 0x47, 0x3B, // REG;
        0x31, 0x30, 0x3B, // 10;
        0x8A, 0x61, 0x62, 0x61, 0x63, 0x3B, // Šabac;
        0x31, 0x3B, // 1;
        0x4C, 0x3B, // L;
        0x31, 0x30, 0x30, 0x3B, // 100;
        0x39, 0x30, 0x0A, // 90\n
      ];
      // These bytes are NOT valid UTF-8 (0x8A is invalid lead byte),
      // so the parser should fall back to Windows-1250.
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
      expect(records[0].municipalityName, 'Šabac');
    });

    test('returns empty list for empty file', () {
      final bytes = utf8.encode('');
      final records = CsvParser.parse(bytes);
      expect(records, isEmpty);
    });

    test('parses CSV with alternative header names', () {
      const content =
          'SifRegije;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;BrojGazdinstavaSva;BrojGazdinstavaAktivna\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;1417;1385\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
      expect(records[0].regionCode, '1');
      expect(records[0].municipalityName, 'Barajevo');
      expect(records[0].totalRegistered, 1417);
      expect(records[0].activeHoldings, 1385);
    });

    test('defaults activeHoldings to 0 when column missing', () {
      const content =
          'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;1417\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
      expect(records[0].totalRegistered, 1417);
      expect(records[0].activeHoldings, 0);
    });

    test('returns empty list when required column missing', () {
      // Missing municipalityName column
      const content =
          'Regija;NazivRegije;SifraOpstine;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;1;Porodicno;1417;1385\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records, isEmpty);
    });

    test('header matching is case-insensitive', () {
      const content =
          'regija;nazivregije;sifraopstine;nazivopstinel;orgoblik;nazivorgoblik;BROJ GAZDINSTAVA;aktivnagazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;1417;1385\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
      expect(records[0].totalRegistered, 1417);
    });

    test('columns in any order still parse correctly', () {
      const content =
          'NazivOpstineL;OrgOblik;broj gazdinstava;AktivnaGazdinstva;Regija;NazivRegije;SifraOpstine;NazivOrgOblik\n'
          'Barajevo;1;1417;1385;1;GRAD BEOGRAD;10;Porodicno\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
      expect(records[0].regionCode, '1');
      expect(records[0].regionName, 'GRAD BEOGRAD');
      expect(records[0].municipalityCode, '10');
      expect(records[0].municipalityName, 'Barajevo');
      expect(records[0].orgForm, OrgForm.familyFarm);
      expect(records[0].totalRegistered, 1417);
      expect(records[0].activeHoldings, 1385);
    });
  });
}
