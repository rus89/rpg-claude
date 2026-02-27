// ABOUTME: Widget tests for the Pregled (overview) screen.
// ABOUTME: Verifies national totals and bar chart render with fixture data.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/pregled/pregled_screen.dart';

final _fixtureSnapshots = [
  Snapshot(
    date: DateTime(2025, 12, 31),
    records: const [
      Record(
        regionCode: '1',
        regionName: 'R1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 1000,
        activeHoldings: 900,
      ),
      Record(
        regionCode: '1',
        regionName: 'R1',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.company,
        totalRegistered: 50,
        activeHoldings: 40,
      ),
    ],
  ),
];

void main() {
  testWidgets('shows total registered and active holdings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
        ],
        child: const MaterialApp(home: PregledScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('1.050'), findsOneWidget); // total registered
    expect(find.text('940'), findsOneWidget); // total active
  });

  testWidgets('renders a bar chart', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
        ],
        child: const MaterialApp(home: PregledScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(BarChart), findsOneWidget);
  });
}

class _FixtureRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtureSnapshots;
}
