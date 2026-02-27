// ABOUTME: Tests for the DataRepository Riverpod provider.
// ABOUTME: Uses a ProviderContainer with overridden data to avoid HTTP calls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';

final _testSnapshots = [
  Snapshot(
    date: DateTime(2025, 12, 31),
    records: [
      const Record(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 100,
        activeHoldings: 90,
      ),
      const Record(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '11',
        municipalityName: 'Čukarica',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 200,
        activeHoldings: 180,
      ),
    ],
  ),
];

void main() {
  group('municipalityNamesProvider', () {
    test('returns sorted unique municipality names from snapshots', () async {
      final container = ProviderContainer(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FakeDataRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dataRepositoryProvider.future);

      final names = container.read(municipalityNamesProvider);
      expect(names, ['Barajevo', 'Čukarica']);
    });
  });
}

class _FakeDataRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _testSnapshots;
}
