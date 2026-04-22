// ABOUTME: Verifies the user-facing product brand exposed by MaterialApp.title.
// ABOUTME: Guards against accidental drift away from "GeoAgro Srbija".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/app.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';

void main() {
  testWidgets('MaterialApp.title is the GeoAgro Srbija brand', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FakeDataRepository()),
        ],
        child: const App(),
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'GeoAgro Srbija');
  });
}

class _FakeDataRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [];
}
