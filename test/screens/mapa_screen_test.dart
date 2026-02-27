// ABOUTME: Widget tests for the Mapa (map) screen.
// ABOUTME: Verifies rendering, polygon tap info card, and card dismissal.

// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/mapa/mapa_screen.dart';

void main() {
  testWidgets('renders FlutterMap widget', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: MaterialApp(home: MapaScreen(tileProvider: _NoOpTileProvider())),
      ),
    );
    await tester.pump();
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('shows info card when polygon hit notifier fires', (
    tester,
  ) async {
    final hitNotifier = ValueNotifier<LayerHitResult<String>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: MaterialApp(
          home: MapaScreen(
            tileProvider: _NoOpTileProvider(),
            hitNotifier: hitNotifier,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Barajevo'), findsNothing);

    hitNotifier.value = const LayerHitResult(
      hitValues: ['Barajevo'],
      coordinate: LatLng(44.0, 21.0),
      point: Point(0, 0),
    );
    await tester.pump();

    expect(find.text('Barajevo'), findsOneWidget);
    expect(find.text('90 aktivnih'), findsOneWidget);

    addTearDown(hitNotifier.dispose);
  });

  testWidgets('close button dismisses info card', (tester) async {
    final hitNotifier = ValueNotifier<LayerHitResult<String>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: MaterialApp(
          home: MapaScreen(
            tileProvider: _NoOpTileProvider(),
            hitNotifier: hitNotifier,
          ),
        ),
      ),
    );
    await tester.pump();

    hitNotifier.value = const LayerHitResult(
      hitValues: ['Barajevo'],
      coordinate: LatLng(44.0, 21.0),
      point: Point(0, 0),
    );
    await tester.pump();

    expect(find.text('Barajevo'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('Barajevo'), findsNothing);

    addTearDown(hitNotifier.dispose);
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
