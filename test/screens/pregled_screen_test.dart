// ABOUTME: Widget tests for the Pregled (overview) screen.
// ABOUTME: Verifies summary cards, delta indicators, activity rate, bar chart, and municipality rankings.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/pregled/pregled_screen.dart';

Record _rec(
  String name, {
  OrgForm orgForm = OrgForm.familyFarm,
  required int registered,
  required int active,
}) => Record(
  regionCode: '1',
  regionName: 'R1',
  municipalityCode: '10',
  municipalityName: name,
  orgForm: orgForm,
  totalRegistered: registered,
  activeHoldings: active,
);

final _snapshot1 = Snapshot(
  date: DateTime(2025, 6, 30),
  records: [
    _rec('Barajevo', registered: 1000, active: 900),
    _rec('Nis', registered: 800, active: 700),
    _rec('Sabac', registered: 700, active: 600),
    _rec('Kragujevac', registered: 600, active: 500),
    _rec('Valjevo', registered: 500, active: 400),
    _rec('Cacak', registered: 400, active: 300),
  ],
);

final _snapshot2 = Snapshot(
  date: DateTime(2025, 12, 31),
  records: [
    _rec('Barajevo', registered: 1100, active: 1000),
    _rec('Nis', registered: 900, active: 800),
    _rec('Sabac', registered: 650, active: 550),
    _rec('Kragujevac', registered: 750, active: 600),
    _rec('Valjevo', registered: 450, active: 350),
    _rec('Cacak', registered: 380, active: 280),
  ],
);

final _fixtureSnapshots = [_snapshot1, _snapshot2];

final _resolver = NameResolver([
  'Barajevo',
  'Nis',
  'Sabac',
  'Kragujevac',
  'Valjevo',
  'Cacak',
]);

Widget _buildApp() => ProviderScope(
  overrides: [
    dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
    nameResolverProvider.overrideWith((ref) async => _resolver),
  ],
  child: const MaterialApp(home: PregledScreen()),
);

void main() {
  testWidgets('shows total registered and active holdings', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // Snapshot2 totals: registered=4230, active=3580
    expect(find.text('4.230'), findsOneWidget);
    expect(find.text('3.580'), findsOneWidget);
  });

  testWidgets('shows delta indicators on summary cards', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // Registered delta: (4230-4000)/4000 = +5.8%
    // Active delta: (3580-3400)/3400 = +5.3%
    expect(find.text('+5,8%'), findsOneWidget);
    expect(find.text('+5,3%'), findsOneWidget);
  });

  testWidgets('shows activity rate card', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // Activity rate: 3580/4230 = 84.6%
    expect(find.text('84,6%'), findsOneWidget);
    expect(find.text('Stopa aktivnosti'), findsOneWidget);
  });

  testWidgets('hides delta when only one snapshot', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _SingleSnapshotRepository(),
          ),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: const MaterialApp(home: PregledScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Should not show any delta percentages
    expect(find.textContaining('%'), findsOneWidget); // only activity rate
  });

  testWidgets('renders a bar chart', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('shows top 5 municipalities by active count', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // Top 5 by active: Barajevo(1000), Nis(800), Kragujevac(600),
    //                   Sabac(550), Valjevo(350)
    expect(find.text('Barajevo'), findsWidgets);
    expect(find.text('Nis'), findsWidgets);
    expect(find.text('Kragujevac'), findsWidgets);
  });

  testWidgets('shows top 5 by growth rate', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // Growth: Kragujevac +20.0%, Nis +14.3%, Barajevo +11.1%
    expect(find.text('+20,0%'), findsOneWidget);
    expect(find.text('+14,3%'), findsOneWidget);
    expect(find.text('+11,1%'), findsOneWidget);
  });

  testWidgets('shows bottom 5 declining municipalities', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    // Declining: Valjevo -12.5%, Sabac -8.3%, Cacak -6.7%
    expect(find.text('-12,5%'), findsOneWidget);
    expect(find.text('-8,3%'), findsOneWidget);
    expect(find.text('-6,7%'), findsOneWidget);
  });
}

class _FixtureRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtureSnapshots;
}

class _SingleSnapshotRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [_snapshot2];
}
