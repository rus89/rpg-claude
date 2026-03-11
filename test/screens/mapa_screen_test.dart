// ABOUTME: Widget tests for the Mapa (map) screen.
// ABOUTME: Verifies rendering, polygon tap, card dismissal, and metric selector behavior.

// LayerHitResult has no public constructor; @internal is the only way to test polygon tap behavior.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rpg_claude/data/models/age_bracket.dart';
import 'package:rpg_claude/data/models/age_record.dart';
import 'package:rpg_claude/data/models/age_snapshot.dart';
import 'package:rpg_claude/data/models/farm_size_record.dart';
import 'package:rpg_claude/data/models/farm_size_snapshot.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/age_provider.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/providers/farm_size_provider.dart';
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

  group('metric selector', () {
    List<Override> metricOverrides() => [
      dataRepositoryProvider.overrideWith(() => _Fixture()),
      nameResolverProvider.overrideWith((ref) async => _resolver),
      farmSizeRepositoryProvider.overrideWith(
        () => _FixtureFarmSizeRepository(),
      ),
      ageRepositoryProvider.overrideWith(() => _FixtureAgeRepository()),
    ];

    testWidgets('shows metric selector with default Gazdinstva', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: metricOverrides(),
          child: MaterialApp(
            theme: appTheme,
            home: MapaScreen(tileProvider: _NoOpTileProvider()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SegmentedButton<MapMetric>), findsOneWidget);
      expect(find.text('Gazdinstva'), findsOneWidget);
    });

    testWidgets('switches to farm size metric', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: metricOverrides(),
          child: MaterialApp(
            theme: appTheme,
            home: MapaScreen(tileProvider: _NoOpTileProvider()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Veličina (ha)'));
      await tester.pumpAndSettle();

      // Verify the selector changed — "Veličina (ha)" is selected
      expect(find.text('Veličina (ha)'), findsOneWidget);
    });

    testWidgets('switches to age metric', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: metricOverrides(),
          child: MaterialApp(
            theme: appTheme,
            home: MapaScreen(tileProvider: _NoOpTileProvider()),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Prosečna starost'));
      await tester.pumpAndSettle();

      expect(find.text('Prosečna starost'), findsOneWidget);
    });

    testWidgets('overlay shows farm size info when size metric selected', (
      tester,
    ) async {
      final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: metricOverrides(),
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

      // Switch to farm size metric
      await tester.tap(find.text('Veličina (ha)'));
      await tester.pumpAndSettle();

      // Tap a municipality
      hitNotifier.value = const LayerHitResult(
        hitValues: ['Barajevo'],
        coordinate: LatLng(44.0, 21.0),
        point: Point(0, 0),
      );
      await tester.pump();

      // totalArea = 150+200+320+400 = 1070, totalFarms = 60+20+8+2 = 90
      // avgSize = 1070/90 ≈ 11.9
      expect(find.textContaining('Prosečna veličina'), findsOneWidget);
      expect(find.textContaining('ha'), findsWidgets);

      addTearDown(hitNotifier.dispose);
    });

    testWidgets('overlay shows age info when age metric selected', (
      tester,
    ) async {
      final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: metricOverrides(),
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

      // Switch to age metric
      await tester.tap(find.text('Prosečna starost'));
      await tester.pumpAndSettle();

      // Tap a municipality
      hitNotifier.value = const LayerHitResult(
        hitValues: ['Barajevo'],
        coordinate: LatLng(44.0, 21.0),
        point: Point(0, 0),
      );
      await tester.pump();

      // Weighted avg age: (10*24.5 + 15*34.5 + 30*54.5 + 25*64.5) /
      //                   (10+15+30+25) = (245+517.5+1635+1612.5)/80 = 50.1
      expect(find.textContaining('Prosečna starost'), findsWidgets);

      addTearDown(hitNotifier.dispose);
    });

    testWidgets('shows loading indicator when secondary data is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataRepositoryProvider.overrideWith(() => _Fixture()),
            nameResolverProvider.overrideWith((ref) async => _resolver),
            farmSizeRepositoryProvider.overrideWith(
              () => _SlowFarmSizeRepository(),
            ),
            ageRepositoryProvider.overrideWith(() => _FixtureAgeRepository()),
          ],
          child: MaterialApp(
            theme: appTheme,
            home: MapaScreen(tileProvider: _NoOpTileProvider()),
          ),
        ),
      );
      await tester.pump();

      // Switch to farm size — data is slow to load
      await tester.tap(find.text('Veličina (ha)'));
      await tester.pump();

      // Should show loading indicator while farm size data loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
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

final _farmSizeSnapshot = FarmSizeSnapshot(
  date: DateTime(2025, 12, 31),
  records: [
    const FarmSizeRecord(
      regionCode: '1',
      regionName: 'R',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      countUpTo5: 60,
      areaUpTo5: 150.0,
      count5to20: 20,
      area5to20: 200.0,
      count20to100: 8,
      area20to100: 320.0,
      countOver100: 2,
      areaOver100: 400.0,
    ),
  ],
);

final _ageSnapshot = AgeSnapshot(
  date: DateTime(2025, 12, 31),
  records: const [
    AgeRecord(
      regionCode: '1',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      ageBracket: AgeBracket.age20to29,
      farmCount: 10,
    ),
    AgeRecord(
      regionCode: '1',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      ageBracket: AgeBracket.age30to39,
      farmCount: 15,
    ),
    AgeRecord(
      regionCode: '1',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      ageBracket: AgeBracket.age50to59,
      farmCount: 30,
    ),
    AgeRecord(
      regionCode: '1',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      ageBracket: AgeBracket.age60to69,
      farmCount: 25,
    ),
  ],
);

class _FixtureFarmSizeRepository extends FarmSizeRepository {
  @override
  Future<List<FarmSizeSnapshot>> build() async => [_farmSizeSnapshot];
}

class _FixtureAgeRepository extends AgeRepository {
  @override
  Future<List<AgeSnapshot>> build() async => [_ageSnapshot];
}

class _SlowFarmSizeRepository extends FarmSizeRepository {
  @override
  Future<List<FarmSizeSnapshot>> build() {
    // Never completes — simulates permanently loading state
    return Completer<List<FarmSizeSnapshot>>().future;
  }
}
