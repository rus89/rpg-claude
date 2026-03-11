// ABOUTME: Riverpod provider for the loaded age structure dataset.
// ABOUTME: AgeRepository is a keepAlive async provider fetching all age structure snapshots.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/age_loader.dart';
import '../data/models/age_snapshot.dart';

part 'age_provider.g.dart';

// keepAlive: true — data is fetched once on cold start and held for the app lifetime.
@Riverpod(keepAlive: true)
class AgeRepository extends _$AgeRepository {
  @override
  Future<List<AgeSnapshot>> build() => AgeLoader.loadAll();
}
