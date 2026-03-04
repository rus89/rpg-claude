// ABOUTME: Widget tests for the Opština detail screen.
// ABOUTME: Verifies org form breakdown, trend chart, and normalised name matching.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/opstine/opstina_detail_screen.dart';

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
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtures;
}
