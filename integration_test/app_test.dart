// ABOUTME: End-to-end integration test — launches full app and verifies live data loads.
// ABOUTME: Makes real HTTP requests to data.gov.rs; no mocks.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rpg_claude/main.dart' as app;
import 'package:rpg_claude/providers/data_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads data, shows totals, and has consistent names', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // After data loads, loading screen should be gone
    expect(find.text('Učitavanje podataka...'), findsNothing);

    // At least one number appears on screen (national total)
    expect(find.textContaining(RegExp(r'\d{3,}')), findsWidgets);

    // Check for municipality names that differ only by diacritics/whitespace
    final element = tester.element(find.byType(Scaffold).first);
    final container = ProviderScope.containerOf(element);
    final snapshots = container.read(dataRepositoryProvider).valueOrNull;
    expect(snapshots, isNotNull, reason: 'Data should have loaded');

    final allNames = snapshots!
        .expand((s) => s.records)
        .map((r) => r.municipalityName)
        .toSet();

    final normalised = <String, List<String>>{};
    for (final name in allNames) {
      final key = _normalise(name);
      normalised.putIfAbsent(key, () => []).add(name);
    }

    final duplicates = normalised.entries
        .where((e) => e.value.length > 1)
        .map((e) => e.value)
        .toList();

    expect(
      duplicates,
      isEmpty,
      reason:
          'Found municipality names that differ only by '
          'diacritics/whitespace: $duplicates',
    );
  });
}

String _normalise(String name) {
  return name
      .toLowerCase()
      .replaceAll('š', 's')
      .replaceAll('đ', 'dj')
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('ž', 'z')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}
