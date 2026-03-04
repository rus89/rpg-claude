// ABOUTME: Riverpod providers for the loaded RPG dataset.
// ABOUTME: DataRepository is the root async provider; derived providers expose filtered views.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/data_loader.dart';
import '../data/models/snapshot.dart';
import '../data/name_resolver.dart';

part 'data_provider.g.dart';

// keepAlive: true — data is fetched once on cold start and held for the app lifetime.
@Riverpod(keepAlive: true)
class DataRepository extends _$DataRepository {
  @override
  Future<List<Snapshot>> build() => DataLoader.loadAll();
}

// Loads GeoJSON municipality names and creates a NameResolver.
@Riverpod(keepAlive: true)
Future<NameResolver> nameResolver(Ref ref) async {
  final raw = await rootBundle.loadString(
    'assets/geojson/serbia_municipalities.geojson',
  );
  final geoJson = jsonDecode(raw) as Map<String, dynamic>;
  final features = geoJson['features'] as List<dynamic>;
  final names = features
      .map(
        (f) =>
            (f['properties'] as Map<String, dynamic>)['NAME_2'] as String? ??
            '',
      )
      .where((n) => n.isNotEmpty)
      .toList();
  return NameResolver(names);
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
