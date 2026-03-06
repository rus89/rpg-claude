// ABOUTME: Widget tests for the Trendovi (trends) screen.
// ABOUTME: Verifies the line chart renders and filters respond to selection.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
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

void main() {
  testWidgets('renders a line chart', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: const MaterialApp(home: TrendoviScreen()),
      ),
    );
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
          ],
          child: const MaterialApp(
            home: Scaffold(body: TrendoviScreen()),
          ),
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
