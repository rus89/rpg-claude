// ABOUTME: Tests for the AgeRepository Riverpod provider.
// ABOUTME: Uses a ProviderContainer with overridden data to avoid HTTP calls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/age_bracket.dart';
import 'package:rpg_claude/data/models/age_record.dart';
import 'package:rpg_claude/data/models/age_snapshot.dart';
import 'package:rpg_claude/providers/age_provider.dart';

final _testSnapshots = [
  AgeSnapshot(
    date: DateTime(2025, 12, 31),
    records: [
      const AgeRecord(
        regionCode: '1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        ageBracket: AgeBracket.age30to39,
        farmCount: 42,
      ),
    ],
  ),
];

void main() {
  group('AgeRepository', () {
    test('provides age snapshots via override', () async {
      final container = ProviderContainer(
        overrides: [
          ageRepositoryProvider.overrideWith(() => _FakeAgeRepository()),
        ],
      );
      addTearDown(container.dispose);

      final snapshots = await container.read(ageRepositoryProvider.future);
      expect(snapshots.length, 1);
      expect(snapshots.first.records.length, 1);
      expect(snapshots.first.records.first.municipalityName, 'Barajevo');
    });
  });
}

class _FakeAgeRepository extends AgeRepository {
  @override
  Future<List<AgeSnapshot>> build() async => _testSnapshots;
}
