// ABOUTME: Tests for the FarmSizeRepository Riverpod provider.
// ABOUTME: Uses a ProviderContainer with overridden data to avoid HTTP calls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/farm_size_record.dart';
import 'package:rpg_claude/data/models/farm_size_snapshot.dart';
import 'package:rpg_claude/providers/farm_size_provider.dart';

final _testSnapshots = [
  FarmSizeSnapshot(
    date: DateTime(2025, 12, 31),
    records: [
      const FarmSizeRecord(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        countUpTo5: 100,
        areaUpTo5: 200.5,
        count5to20: 50,
        area5to20: 500.75,
        count20to100: 20,
        area20to100: 1000.25,
        countOver100: 5,
        areaOver100: 800.0,
      ),
    ],
  ),
];

void main() {
  group('FarmSizeRepository', () {
    test('provides farm size snapshots via override', () async {
      final container = ProviderContainer(
        overrides: [
          farmSizeRepositoryProvider.overrideWith(
            () => _FakeFarmSizeRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshots = await container.read(farmSizeRepositoryProvider.future);
      expect(snapshots.length, 1);
      expect(snapshots.first.records.length, 1);
      expect(snapshots.first.records.first.municipalityName, 'Barajevo');
    });
  });
}

class _FakeFarmSizeRepository extends FarmSizeRepository {
  @override
  Future<List<FarmSizeSnapshot>> build() async => _testSnapshots;
}
