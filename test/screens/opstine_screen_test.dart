// ABOUTME: Widget tests for the Opštine (municipalities) screen.
// ABOUTME: Covers list rendering, search filtering, and navigation to detail.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/opstine/opstine_screen.dart';

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
        totalRegistered: 100,
        activeHoldings: 90,
      ),
      Record(
        regionCode: '1',
        regionName: 'R1',
        municipalityCode: '11',
        municipalityName: 'Čukarica',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 200,
        activeHoldings: 180,
      ),
    ],
  ),
];

void main() {
  testWidgets('shows all municipality names', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: const MaterialApp(home: OpstineScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Barajevo'), findsOneWidget);
    expect(find.text('Čukarica'), findsOneWidget);
  });

  testWidgets('search filters the list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: const MaterialApp(home: OpstineScreen()),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bara');
    await tester.pump();
    expect(find.text('Barajevo'), findsOneWidget);
    expect(find.text('Čukarica'), findsNothing);
  });

  testWidgets('clear button resets search', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
        child: const MaterialApp(home: OpstineScreen()),
      ),
    );
    await tester.pump();

    // Type a search term
    await tester.enterText(find.byType(TextField), 'Bara');
    await tester.pump();
    expect(find.text('Čukarica'), findsNothing);

    // Clear button should be visible
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    // Both municipalities should be visible again
    expect(find.text('Barajevo'), findsOneWidget);
    expect(find.text('Čukarica'), findsOneWidget);

    // Clear button should be hidden when search is empty
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders municipality list at desktop width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
          child: const MaterialApp(home: Scaffold(body: OpstineScreen())),
        ),
      );
      await tester.pump();
      expect(find.text('Barajevo'), findsOneWidget);
      expect(find.text('Čukarica'), findsOneWidget);
    });
  });
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtureSnapshots;
}
