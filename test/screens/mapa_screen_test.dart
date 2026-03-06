// ABOUTME: Widget tests for the Mapa (map) screen.
// ABOUTME: Verifies rendering, polygon tap info card, and card dismissal.

// LayerHitResult has no public constructor; @internal is the only way to test polygon tap behavior.
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
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/mapa/mapa_screen.dart';
import 'package:rpg_claude/theme.dart';

final _resolver = NameResolver(['Barajevo', 'NoviBeograd', 'Inđija']);

void main() {
  testWidgets('renders FlutterMap widget', (tester) async {
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
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('shows info card when polygon hit notifier fires', (
    tester,
  ) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
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
    expect(find.text('90'), findsNWidgets(2)); // total + breakdown row
    expect(find.text('Aktivnih gazdinstava'), findsOneWidget);

    addTearDown(hitNotifier.dispose);
  });

  testWidgets('close button dismisses info card', (tester) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
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

  testWidgets('tapping empty map space dismisses info card', (tester) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
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

    // Tap empty space — notifier fires with null
    hitNotifier.value = null;
    await tester.pump();
    expect(find.text('Barajevo'), findsNothing);

    addTearDown(hitNotifier.dispose);
  });

  testWidgets('overlay shows org form breakdown', (tester) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: MaterialApp(
          theme: appTheme,
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

    // Should show org form name and count
    expect(find.text('Porodično gazdinstvo'), findsOneWidget);
    expect(find.text('90'), findsNWidgets(2)); // total + breakdown row

    addTearDown(hitNotifier.dispose);
  });

  testWidgets('matches GeoJSON name without spaces to CSV name with spaces', (
    tester,
  ) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _SpacedNameFixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: MaterialApp(
          home: MapaScreen(
            tileProvider: _NoOpTileProvider(),
            hitNotifier: hitNotifier,
          ),
        ),
      ),
    );
    await tester.pump();

    // GeoJSON fires 'NoviBeograd' (no space), CSV has 'Novi Beograd' (space).
    // The overlay should split CamelCase and show "Novi Beograd".
    hitNotifier.value = const LayerHitResult(
      hitValues: ['NoviBeograd'],
      coordinate: LatLng(44.0, 21.0),
      point: Point(0, 0),
    );
    await tester.pump();

    expect(find.text('Novi Beograd'), findsOneWidget);
    expect(find.text('50'), findsNWidgets(2)); // total + breakdown row

    addTearDown(hitNotifier.dispose);
  });

  testWidgets('shows explanatory note when tapped municipality has 0 active', (
    tester,
  ) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: MaterialApp(
          home: MapaScreen(
            tileProvider: _NoOpTileProvider(),
            hitNotifier: hitNotifier,
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap a municipality that doesn't exist in data → totalActive = 0
    hitNotifier.value = const LayerHitResult(
      hitValues: ['UnknownMunicipality'],
      coordinate: LatLng(44.0, 21.0),
      point: Point(0, 0),
    );
    await tester.pump();

    expect(find.textContaining('objedinjeni'), findsOneWidget);

    addTearDown(hitNotifier.dispose);
  });

  testWidgets('matches GeoJSON đ to CSV ? for count lookup', (tester) async {
    final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _DjFixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: MaterialApp(
          home: MapaScreen(
            tileProvider: _NoOpTileProvider(),
            hitNotifier: hitNotifier,
          ),
        ),
      ),
    );
    await tester.pump();

    // GeoJSON fires 'Inđija', CSV has 'In?ija' (corrupted đ).
    // Overlay shows GeoJSON name; count matches via normalisation.
    hitNotifier.value = const LayerHitResult(
      hitValues: ['Inđija'],
      coordinate: LatLng(44.0, 21.0),
      point: Point(0, 0),
    );
    await tester.pump();

    expect(find.text('Inđija'), findsOneWidget);
    expect(find.text('70'), findsNWidgets(2)); // total + breakdown row

    addTearDown(hitNotifier.dispose);
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders map at desktop width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataRepositoryProvider.overrideWith(() => _Fixture()),
            nameResolverProvider.overrideWith((ref) async => _resolver),
          ],
          child: MaterialApp(
            home: Scaffold(body: MapaScreen(tileProvider: _NoOpTileProvider())),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });
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

class _SpacedNameFixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [
    Snapshot(
      date: DateTime(2025, 12, 31),
      records: const [
        Record(
          regionCode: '1',
          regionName: 'R',
          municipalityCode: '13',
          municipalityName: 'Novi Beograd',
          orgForm: OrgForm.familyFarm,
          totalRegistered: 60,
          activeHoldings: 50,
        ),
      ],
    ),
  ];
}

class _DjFixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [
    Snapshot(
      date: DateTime(2025, 12, 31),
      records: const [
        Record(
          regionCode: '2',
          regionName: 'R',
          municipalityCode: '22',
          // CSV has '?' where đ should be (data quality issue from source)
          municipalityName: 'In?ija',
          orgForm: OrgForm.familyFarm,
          totalRegistered: 80,
          activeHoldings: 70,
        ),
      ],
    ),
  ];
}
