// ABOUTME: Riverpod provider for the loaded farm size dataset.
// ABOUTME: FarmSizeRepository is a keepAlive async provider fetching all farm size snapshots.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/farm_size_loader.dart';
import '../data/models/farm_size_snapshot.dart';

part 'farm_size_provider.g.dart';

// keepAlive: true — data is fetched once on cold start and held for the app lifetime.
@Riverpod(keepAlive: true)
class FarmSizeRepository extends _$FarmSizeRepository {
  @override
  Future<List<FarmSizeSnapshot>> build() => FarmSizeLoader.loadAll();
}
