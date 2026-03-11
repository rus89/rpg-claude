// ABOUTME: Tests for AgeParser CSV parsing with various column name and data format quirks.
// ABOUTME: Covers standard labels, "okt.19" bug, column variants, encoding fallback, and error handling.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/age_parser.dart';
import 'package:rpg_claude/data/models/age_bracket.dart';

// Standard header with BrojDomacinstva column name
const _validCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n'
    '1;10;Barajevo;10 - 19;100\n'
    '1;10;Barajevo;20 - 29;200\n'
    '1;10;Barajevo;30 - 39;300\n';

// "okt.19" format age label
const _oktCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n'
    '1;10;Barajevo;okt.19;150\n'
    '1;10;Barajevo;20 - 29;250\n';

// BrojPG column name variant
const _brojPgCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojPG\n'
    '1;10;Barajevo;10 - 19;100\n';

// Broj Domacinstva (with space) column name variant
const _brojDomacinstvaCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;Broj Domacinstva\n'
    '1;10;Barajevo;10 - 19;100\n';

// Broj PG (with space) column name variant
const _brojPgSpaceCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;Broj PG\n'
    '1;10;Barajevo;10 - 19;100\n';

// Missing required column (no age bracket)
const _missingColumnCsv =
    'Regija;SifraOpstine;NazivOpstineL;BrojDomacinstva\n'
    '1;10;Barajevo;100\n';

// Row with unknown age bracket (should be skipped)
const _unknownBracketCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n'
    '1;10;Barajevo;0 - 9;50\n'
    '1;10;Barajevo;20 - 29;200\n';

// Row with non-numeric farm count (should be skipped)
const _badCountCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n'
    '1;10;Barajevo;10 - 19;ABC\n'
    '1;10;Barajevo;20 - 29;200\n';

// Trailing semicolons
const _trailingSemicolonCsv =
    'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva;;\n'
    '1;10;Barajevo;10 - 19;100;;\n';

// Extra columns (Reon, NazivRegije)
const _extraColumnsCsv =
    'Reon;Regija;NazivRegije;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n'
    'BG;1;GRAD BEOGRAD;10;Barajevo;10 - 19;100\n';

// OpsegGodina (no space) header variant
const _opsegGodinaCsv =
    'Regija;SifraOpstine;NazivOpstineL;OpsegGodina;BrojDomacinstva\n'
    '1;10;Barajevo;10 - 19;100\n';

// BirthRange header variant (used in real data)
const _birthRangeCsv =
    'Regija;SifraOpstine;NazivOpstineL;BirthRange;BrojPG\n'
    '1;10;Barajevo;okt.19;50\n'
    '1;10;Barajevo;20 - 29;100\n';

void main() {
  group('AgeParser', () {
    test('parses valid CSV with standard age labels', () {
      final records = AgeParser.parse(utf8.encode(_validCsv));
      expect(records.length, 3);
      expect(records[0].municipalityName, 'Barajevo');
      expect(records[0].ageBracket, AgeBracket.age10to19);
      expect(records[0].farmCount, 100);
      expect(records[1].ageBracket, AgeBracket.age20to29);
      expect(records[1].farmCount, 200);
      expect(records[2].ageBracket, AgeBracket.age30to39);
      expect(records[2].farmCount, 300);
    });

    test('parses CSV with "okt.19" format age labels', () {
      final records = AgeParser.parse(utf8.encode(_oktCsv));
      expect(records.length, 2);
      expect(records[0].ageBracket, AgeBracket.age10to19);
      expect(records[0].farmCount, 150);
      expect(records[1].ageBracket, AgeBracket.age20to29);
      expect(records[1].farmCount, 250);
    });

    test('parses BrojPG column name variant', () {
      final records = AgeParser.parse(utf8.encode(_brojPgCsv));
      expect(records.length, 1);
      expect(records[0].farmCount, 100);
    });

    test('parses Broj Domacinstva column name variant', () {
      final records = AgeParser.parse(utf8.encode(_brojDomacinstvaCsv));
      expect(records.length, 1);
      expect(records[0].farmCount, 100);
    });

    test('parses Broj PG column name variant', () {
      final records = AgeParser.parse(utf8.encode(_brojPgSpaceCsv));
      expect(records.length, 1);
      expect(records[0].farmCount, 100);
    });

    test('returns empty list when required column is missing', () {
      final records = AgeParser.parse(utf8.encode(_missingColumnCsv));
      expect(records, isEmpty);
    });

    test('returns empty list for empty input', () {
      final records = AgeParser.parse([]);
      expect(records, isEmpty);
    });

    test('skips rows with unknown age brackets', () {
      final records = AgeParser.parse(utf8.encode(_unknownBracketCsv));
      expect(records.length, 1);
      expect(records[0].ageBracket, AgeBracket.age20to29);
    });

    test('skips rows with non-numeric farm count', () {
      final records = AgeParser.parse(utf8.encode(_badCountCsv));
      expect(records.length, 1);
      expect(records[0].ageBracket, AgeBracket.age20to29);
    });

    test('handles trailing semicolons', () {
      final records = AgeParser.parse(utf8.encode(_trailingSemicolonCsv));
      expect(records.length, 1);
      expect(records[0].municipalityName, 'Barajevo');
    });

    test('handles extra columns (Reon, NazivRegije)', () {
      final records = AgeParser.parse(utf8.encode(_extraColumnsCsv));
      expect(records.length, 1);
      expect(records[0].regionCode, '1');
      expect(records[0].municipalityName, 'Barajevo');
    });

    test('handles OpsegGodina (no space) header variant', () {
      final records = AgeParser.parse(utf8.encode(_opsegGodinaCsv));
      expect(records.length, 1);
      expect(records[0].ageBracket, AgeBracket.age10to19);
    });

    test('handles BirthRange header variant from real data', () {
      final records = AgeParser.parse(utf8.encode(_birthRangeCsv));
      expect(records.length, 2);
      expect(records[0].ageBracket, AgeBracket.age10to19);
      expect(records[0].farmCount, 50);
      expect(records[1].ageBracket, AgeBracket.age20to29);
      expect(records[1].farmCount, 100);
    });

    test('stores regionCode and municipalityCode when present', () {
      final records = AgeParser.parse(utf8.encode(_validCsv));
      expect(records[0].regionCode, '1');
      expect(records[0].municipalityCode, '10');
    });

    test('falls back to Windows-1250 when UTF-8 fails', () {
      final header = utf8.encode(
        'Regija;SifraOpstine;NazivOpstineL;Opseg Godina;BrojDomacinstva\n',
      );
      // Row with Windows-1250 encoded Č (0xC8) and č (0xE8): "Čačak"
      final row = [
        0x31, 0x3B, // 1;
        0x31, 0x30, 0x3B, // 10;
        0xC8, 0x61, 0xE8, 0x61, 0x6B, 0x3B, // Čačak; (Windows-1250)
        0x31, 0x30, 0x20, 0x2D, 0x20, 0x31, 0x39, 0x3B, // 10 - 19;
        0x31, 0x30, 0x30, 0x0A, // 100\n
      ];
      final bytes = [...header, ...row];
      final records = AgeParser.parse(bytes);
      expect(records.length, 1);
      expect(records.first.municipalityName, 'Čačak');
    });
  });
}
