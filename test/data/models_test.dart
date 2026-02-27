// ABOUTME: Tests for core data model types.
// ABOUTME: Covers OrgForm, Record, and Snapshot construction and equality.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';

void main() {
  group('OrgForm', () {
    test('fromCode returns correct enum value', () {
      expect(OrgForm.fromCode(1), OrgForm.familyFarm);
      expect(OrgForm.fromCode(7), OrgForm.religiousOrganization);
    });

    test('fromCode throws for unknown code', () {
      expect(() => OrgForm.fromCode(99), throwsArgumentError);
    });
  });

  group('Record', () {
    test('constructs with all fields', () {
      const record = Record(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 1417,
        activeHoldings: 1385,
      );
      expect(record.municipalityName, 'Barajevo');
      expect(record.activeHoldings, 1385);
    });
  });

  group('Snapshot', () {
    test('constructs with date and records', () {
      final snapshot = Snapshot(
        date: DateTime(2025, 12, 31),
        records: [],
      );
      expect(snapshot.date.year, 2025);
      expect(snapshot.records, isEmpty);
    });
  });
}
