// ABOUTME: Riverpod providers for the loaded RPG dataset.
// ABOUTME: DataRepository is the root async provider; derived providers expose filtered views.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/data_loader.dart';
import '../data/models/snapshot.dart';

part 'data_provider.g.dart';

// keepAlive: true — data is fetched once on cold start and held for the app lifetime.
@Riverpod(keepAlive: true)
class DataRepository extends _$DataRepository {
  @override
  Future<List<Snapshot>> build() => DataLoader.loadAll();
}

// Returns all unique municipality names sorted alphabetically.
@riverpod
List<String> municipalityNames(Ref ref) {
  final snapshots = ref.watch(dataRepositoryProvider).valueOrNull ?? [];
  final names =
      snapshots
          .expand((s) => s.records)
          .map((r) => r.municipalityName)
          .toSet()
          .toList()
        ..sort();
  return names;
}
