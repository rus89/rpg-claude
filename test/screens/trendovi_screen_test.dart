// ABOUTME: Widget tests for the Trendovi (trends) screen.
// ABOUTME: Verifies the line chart renders, dataset selector works, and filters respond to selection.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:rpg_claude/screens/trendovi/trendovi_screen.dart';

final _resolver = NameResolver(['Barajevo']);

final _fixtures = [
  Snapshot(
    date: DateTime(2024, 1, 1),
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
  Snapshot(
    date: DateTime(2025, 1, 1),
    records: const [
      Record(
        regionCode: '1',
        regionName: 'R',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 110,
        activeHoldings: 100,
      ),
    ],
  ),
];

final _farmSizeFixtures = [
  FarmSizeSnapshot(
    date: DateTime(2024, 1, 1),
    records: const [
      FarmSizeRecord(
        regionCode: '1',
        regionName: 'R',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        countUpTo5: 500,
        areaUpTo5: 800.0,
        count5to20: 100,
        area5to20: 1000.0,
        count20to100: 20,
        area20to100: 800.0,
        countOver100: 3,
        areaOver100: 500.0,
      ),
    ],
  ),
  FarmSizeSnapshot(
    date: DateTime(2025, 1, 1),
    records: const [
      FarmSizeRecord(
        regionCode: '1',
        regionName: 'R',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        countUpTo5: 520,
        areaUpTo5: 850.0,
        count5to20: 110,
        area5to20: 1100.0,
        count20to100: 22,
        area20to100: 900.0,
        countOver100: 4,
        areaOver100: 600.0,
      ),
    ],
  ),
];

final _ageFixtures = [
  AgeSnapshot(
    date: DateTime(2024, 1, 1),
    records: const [
      AgeRecord(
        regionCode: '1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        ageBracket: AgeBracket.age30to39,
        farmCount: 50,
      ),
      AgeRecord(
        regionCode: '1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        ageBracket: AgeBracket.age50to59,
        farmCount: 100,
      ),
    ],
  ),
  AgeSnapshot(
    date: DateTime(2025, 1, 1),
    records: const [
      AgeRecord(
        regionCode: '1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        ageBracket: AgeBracket.age30to39,
        farmCount: 55,
      ),
      AgeRecord(
        regionCode: '1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        ageBracket: AgeBracket.age50to59,
        farmCount: 110,
      ),
    ],
  ),
];

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      dataRepositoryProvider.overrideWith(() => _Fixture()),
      nameResolverProvider.overrideWith((ref) async => _resolver),
      farmSizeRepositoryProvider.overrideWith(() => _FarmSizeFixture()),
      ageRepositoryProvider.overrideWith(() => _AgeFixture()),
    ],
    child: const MaterialApp(home: TrendoviScreen()),
  );
}

void main() {
  testWidgets('renders a line chart', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('shows dataset segmented button', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Gazdinstva'), findsOneWidget);
    expect(find.text('Veličina'), findsOneWidget);
    expect(find.text('Starost'), findsOneWidget);
  });

  testWidgets('shows org form chips by default', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Porodično gazdinstvo'), findsOneWidget);
  });

  testWidgets('shows size bracket chips when Veličina selected', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('Veličina'));
    await tester.pump();
    expect(find.text('≤5 ha'), findsOneWidget);
    expect(find.text('5–20 ha'), findsOneWidget);
    expect(find.text('20–100 ha'), findsOneWidget);
    expect(find.text('>100 ha'), findsOneWidget);
  });

  testWidgets('shows age bracket chips when Starost selected', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('Starost'));
    await tester.pump();
    // AgeBracket.age30to39.displayName is "30–39"
    expect(find.text('30\u201339'), findsOneWidget);
  });

  testWidgets('renders line chart for Veličina dataset', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('Veličina'));
    await tester.pump();
    // Extra pump to let the farmSizeRepository async provider resolve
    await tester.pump();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('renders line chart for Starost dataset', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    await tester.tap(find.text('Starost'));
    await tester.pump();
    // Extra pump to let the ageRepository async provider resolve
    await tester.pump();
    expect(find.byType(LineChart), findsOneWidget);
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders line chart at desktop width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataRepositoryProvider.overrideWith(() => _Fixture()),
            nameResolverProvider.overrideWith((ref) async => _resolver),
            farmSizeRepositoryProvider.overrideWith(() => _FarmSizeFixture()),
            ageRepositoryProvider.overrideWith(() => _AgeFixture()),
          ],
          child: const MaterialApp(home: Scaffold(body: TrendoviScreen())),
        ),
      );
      await tester.pump();
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtures;
}

class _FarmSizeFixture extends FarmSizeRepository {
  @override
  Future<List<FarmSizeSnapshot>> build() async => _farmSizeFixtures;
}

class _AgeFixture extends AgeRepository {
  @override
  Future<List<AgeSnapshot>> build() async => _ageFixtures;
}
