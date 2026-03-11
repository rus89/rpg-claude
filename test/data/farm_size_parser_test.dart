// ABOUTME: Tests for FarmSizeParser CSV parsing with various data quirks.
// ABOUTME: Covers decimal formats, dash-as-zero, header variants, encoding fallback, and error handling.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/farm_size_parser.dart';

// Standard header + one data row with comma-only decimals
const _validCsv =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;50;500,75;20;1000,25;5;800,0\n';

// Dot-thousands + comma decimal: 1.996,4809
const _dotThousandsCsv =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;1.996,4809;50;2.500,123;20;10.000,0;5;800,0\n';

// Dash means zero
const _dashCsv =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;-;-;20;1000,25;-;-\n';

// Spaces in headers
const _spacedHeaderCsv =
    ' Regija ; NazivRegije ; SifraOpstine ; NazivOpstineL ; Broj PG <=5 ; Povrsina Ukupno <=5 ; Broj PG 5-20 ; Povrsina Ukupno 5-20 ; Broj PG 20-100 ; Povrsina Ukupno 20-100 ; Broj PG >100 ; Povrsina Ukupno >100 \n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;50;500,75;20;1000,25;5;800,0\n';

// Trailing semicolons
const _trailingSemicolonCsv =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100;;\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;50;500,75;20;1000,25;5;800,0;;\n';

// Missing required column (no municipalityName)
const _missingColumnCsv =
    'Regija;NazivRegije;SifraOpstine;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;100;200,5;50;500,75;20;1000,25;5;800,0\n';

// Row with parse error (non-numeric count)
const _badRowCsv =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;Barajevo;ABC;200,5;50;500,75;20;1000,25;5;800,0\n'
    '1;GRAD BEOGRAD;11;Vozdovac;100;200,5;50;500,75;20;1000,25;5;800,0\n';

// Alternate header variant with spaces around operators
const _alternateHeaderCsv =
    'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <= 5;Povrsina Ukupno <= 5;Broj PG 5 - 20;Povrsina Ukupno 5 - 20;Broj PG 20 - 100;Povrsina Ukupno 20 - 100;Broj PG > 100;Povrsina Ukupno > 100\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;50;500,75;20;1000,25;5;800,0\n';

// sifregije header variant
const _sifregijeCsv =
    'SifRegije;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
    '1;GRAD BEOGRAD;10;Barajevo;100;200,5;50;500,75;20;1000,25;5;800,0\n';

void main() {
  group('FarmSizeParser', () {
    test('parses valid CSV with comma-only decimals', () {
      final records = FarmSizeParser.parse(utf8.encode(_validCsv));
      expect(records.length, 1);
      final r = records.first;
      expect(r.regionCode, '1');
      expect(r.regionName, 'GRAD BEOGRAD');
      expect(r.municipalityCode, '10');
      expect(r.municipalityName, 'Barajevo');
      expect(r.countUpTo5, 100);
      expect(r.areaUpTo5, closeTo(200.5, 0.0001));
      expect(r.count5to20, 50);
      expect(r.area5to20, closeTo(500.75, 0.0001));
      expect(r.count20to100, 20);
      expect(r.area20to100, closeTo(1000.25, 0.0001));
      expect(r.countOver100, 5);
      expect(r.areaOver100, closeTo(800.0, 0.0001));
    });

    test('parses dot-thousands + comma-decimal format', () {
      final records = FarmSizeParser.parse(utf8.encode(_dotThousandsCsv));
      expect(records.length, 1);
      final r = records.first;
      expect(r.areaUpTo5, closeTo(1996.4809, 0.0001));
      expect(r.area5to20, closeTo(2500.123, 0.0001));
      expect(r.area20to100, closeTo(10000.0, 0.0001));
    });

    test('treats dash as zero for count and area fields', () {
      final records = FarmSizeParser.parse(utf8.encode(_dashCsv));
      expect(records.length, 1);
      final r = records.first;
      expect(r.count5to20, 0);
      expect(r.area5to20, 0.0);
      expect(r.countOver100, 0);
      expect(r.areaOver100, 0.0);
    });

    test('handles headers with leading/trailing spaces', () {
      final records = FarmSizeParser.parse(utf8.encode(_spacedHeaderCsv));
      expect(records.length, 1);
      expect(records.first.municipalityName, 'Barajevo');
    });

    test('handles trailing semicolons', () {
      final records = FarmSizeParser.parse(utf8.encode(_trailingSemicolonCsv));
      expect(records.length, 1);
      expect(records.first.municipalityName, 'Barajevo');
    });

    test('returns empty list when required column is missing', () {
      final records = FarmSizeParser.parse(utf8.encode(_missingColumnCsv));
      expect(records, isEmpty);
    });

    test('returns empty list for empty input', () {
      final records = FarmSizeParser.parse([]);
      expect(records, isEmpty);
    });

    test('skips rows with parse errors', () {
      final records = FarmSizeParser.parse(utf8.encode(_badRowCsv));
      expect(records.length, 1);
      expect(records.first.municipalityName, 'Vozdovac');
    });

    test('parses alternate header variant with spaces around operators', () {
      final records = FarmSizeParser.parse(utf8.encode(_alternateHeaderCsv));
      expect(records.length, 1);
      expect(records.first.countUpTo5, 100);
    });

    test('parses SifRegije header variant', () {
      final records = FarmSizeParser.parse(utf8.encode(_sifregijeCsv));
      expect(records.length, 1);
      expect(records.first.regionCode, '1');
    });

    test('handles dot-thousands separator in count fields', () {
      const csv =
          'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n'
          '1;GRAD BEOGRAD;10;Barajevo;1.234;200,5;50;500,75;20;1000,25;5;800,0\n';
      final records = FarmSizeParser.parse(utf8.encode(csv));
      expect(records.length, 1);
      expect(records.first.countUpTo5, 1234);
    });

    test('falls back to Windows-1250 when UTF-8 fails', () {
      // Windows-1250 encoded: "Čačak" → bytes C8, E8 for Č, č
      final header = utf8.encode(
        'Regija;NazivRegije;SifraOpstine;NazivOpstineL;Broj PG <=5;Povrsina Ukupno <=5;Broj PG 5-20;Povrsina Ukupno 5-20;Broj PG 20-100;Povrsina Ukupno 20-100;Broj PG >100;Povrsina Ukupno >100\n',
      );
      // Row with Windows-1250 encoded Č (0xC8) and č (0xE8): "Čačak"
      final row = [
        0x31, 0x3B, // 1;
        0x52, 0x45, 0x47, 0x3B, // REG;
        0x31, 0x30, 0x3B, // 10;
        0xC8, 0x61, 0xE8, 0x61, 0x6B, 0x3B, // Čačak; (Windows-1250)
        0x31, 0x30, 0x30, 0x3B, // 100;
        0x32, 0x30, 0x30, 0x3B, // 200;
        0x35, 0x30, 0x3B, // 50;
        0x35, 0x30, 0x30, 0x3B, // 500;
        0x32, 0x30, 0x3B, // 20;
        0x31, 0x30, 0x30, 0x30, 0x3B, // 1000;
        0x35, 0x3B, // 5;
        0x38, 0x30, 0x30, 0x0A, // 800\n
      ];
      final bytes = [...header, ...row];
      final records = FarmSizeParser.parse(bytes);
      expect(records.length, 1);
      expect(records.first.municipalityName, 'Čačak');
    });
  });
}
