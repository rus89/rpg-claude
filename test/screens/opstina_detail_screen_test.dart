// ABOUTME: Widget tests for the Opština detail screen.
// ABOUTME: Verifies org form breakdown, trend chart, farm size, age structure, and normalised name matching.

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
import 'package:rpg_claude/screens/opstine/opstina_detail_screen.dart';

final _resolver = NameResolver(['Barajevo']);

final _farmSizeFixture = [
  FarmSizeSnapshot(
    date: DateTime(2025, 1, 1),
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
];

final _ageFixture = [
  AgeSnapshot(
    date: DateTime(2025, 1, 1),
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
        farmCount: 120,
      ),
    ],
  ),
];

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
      Record(
        regionCode: '1',
        regionName: 'R',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.company,
        totalRegistered: 10,
        activeHoldings: 8,
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
      Record(
        regionCode: '1',
        regionName: 'R',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.company,
        totalRegistered: 12,
        activeHoldings: 10,
      ),
    ],
  ),
];

Widget _buildApp({String name = 'Barajevo'}) => ProviderScope(
  overrides: [
    dataRepositoryProvider.overrideWith(() => _Fixture()),
    nameResolverProvider.overrideWith((ref) async => _resolver),
    farmSizeRepositoryProvider.overrideWith(() => _FarmSizeFixture()),
    ageRepositoryProvider.overrideWith(() => _AgeFixture()),
  ],
  child: MaterialApp(home: OpstinaDetailScreen(municipalityName: name)),
);

void main() {
  testWidgets('shows municipality name in app bar', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Barajevo'), findsOneWidget);
  });

  testWidgets('shows org form breakdown for latest snapshot', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.text('Porodično gazdinstvo'), findsOneWidget);
    expect(find.text('Preduzeće'), findsOneWidget);
    expect(find.text('100'), findsWidgets);
    expect(find.text('10'), findsWidgets);
  });

  testWidgets('renders a line chart', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('shows farm size bar chart for municipality', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Veličina gazdinstava'), findsOneWidget);
    expect(find.byType(BarChart), findsAny);
  });

  testWidgets('shows total area text', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // 800 + 1000 + 800 + 500 = 3100.0
    expect(find.textContaining('Ukupna površina'), findsOneWidget);
    expect(find.textContaining('3.100'), findsOneWidget);
  });

  testWidgets('shows age distribution for municipality', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Starosna struktura nosioca'), findsOneWidget);
    expect(find.byType(BarChart), findsAny);
  });

  testWidgets('hides farm size section on error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
          farmSizeRepositoryProvider.overrideWith(() => _FarmSizeError()),
          ageRepositoryProvider.overrideWith(() => _AgeFixture()),
        ],
        child: const MaterialApp(
          home: OpstinaDetailScreen(municipalityName: 'Barajevo'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Veličina gazdinstava'), findsNothing);
  });

  testWidgets('hides age section on error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
          farmSizeRepositoryProvider.overrideWith(() => _FarmSizeFixture()),
          ageRepositoryProvider.overrideWith(() => _AgeError()),
        ],
        child: const MaterialApp(
          home: OpstinaDetailScreen(municipalityName: 'Barajevo'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Starosna struktura nosioca'), findsNothing);
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders org forms and chart side by side', (tester) async {
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
          child: const MaterialApp(
            home: Scaffold(
              body: OpstinaDetailScreen(municipalityName: 'Barajevo'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Porodično gazdinstvo'), findsOneWidget);
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
  Future<List<FarmSizeSnapshot>> build() async => _farmSizeFixture;
}

class _FarmSizeError extends FarmSizeRepository {
  @override
  Future<List<FarmSizeSnapshot>> build() async => throw Exception('fail');
}

class _AgeFixture extends AgeRepository {
  @override
  Future<List<AgeSnapshot>> build() async => _ageFixture;
}

class _AgeError extends AgeRepository {
  @override
  Future<List<AgeSnapshot>> build() async => throw Exception('fail');
}
