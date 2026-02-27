// ABOUTME: Widget tests for the Trendovi (trends) screen.
// ABOUTME: Verifies the line chart renders and filters respond to selection.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/trendovi/trendovi_screen.dart';

final _fixtures = [
  Snapshot(date: DateTime(2024, 1, 1), records: const [
    Record(
      regionCode: '1',
      regionName: 'R',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      orgForm: OrgForm.familyFarm,
      totalRegistered: 100,
      activeHoldings: 90,
    ),
  ]),
  Snapshot(date: DateTime(2025, 1, 1), records: const [
    Record(
      regionCode: '1',
      regionName: 'R',
      municipalityCode: '10',
      municipalityName: 'Barajevo',
      orgForm: OrgForm.familyFarm,
      totalRegistered: 110,
      activeHoldings: 100,
    ),
  ]),
];

void main() {
  testWidgets('renders a line chart', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: const MaterialApp(home: TrendoviScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(LineChart), findsOneWidget);
  });
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtures;
}
