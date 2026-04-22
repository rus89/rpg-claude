// ABOUTME: Widget test verifying the Mapa screen shows OSM tile attribution.
// ABOUTME: OSM Tile Usage Policy requires visible attribution whenever OSM tiles are displayed.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/mapa/mapa_screen.dart';

final _resolver = NameResolver(['Barajevo']);

void main() {
  testWidgets('shows OpenStreetMap attribution text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: MaterialApp(home: MapaScreen(tileProvider: _NoOpTileProvider())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
  });
}

// Returns a transparent 1x1 PNG without making network requests.
class _NoOpTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [
    Snapshot(
      date: DateTime(2025, 12, 31),
      records: const [
        Record(
          regionCode: '1',
          regionName: 'R',
          municipalityCode: '10',
          municipalityName: 'Barajevo',
          orgForm: OrgForm.familyFarm,
          totalRegistered: 100,
          activeHoldings: 90,
        ),
      ],
    ),
  ];
}
