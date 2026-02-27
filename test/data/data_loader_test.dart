// ABOUTME: Tests for DataLoader snapshot assembly logic.
// ABOUTME: Verifies that snapshots are built correctly from parsed records.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/data_loader.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';

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
}
