// ABOUTME: Smoke test verifying the app widget tree initialises without errors.
// ABOUTME: Overrides DataRepository to avoid real HTTP calls during testing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/app.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';

void main() {
  testWidgets('app renders without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FakeDataRepository()),
        ],
        child: const App(),
      ),
    );
    await tester.pump();
    // App mounted — no exceptions thrown.
  });
}

class _FakeDataRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [];
}
