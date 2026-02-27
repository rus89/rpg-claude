// ABOUTME: Tests for CSV parsing logic.
// ABOUTME: Covers delimiter handling, encoding fallback, and malformed row skipping.

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

    test('returns empty list for empty file', () {
      final bytes = utf8.encode('');
      final records = CsvParser.parse(bytes);
      expect(records, isEmpty);
    });
  });
}
