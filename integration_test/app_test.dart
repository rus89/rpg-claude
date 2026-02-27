// ABOUTME: End-to-end integration test — launches full app and verifies live data loads.
// ABOUTME: Makes real HTTP requests to data.gov.rs; no mocks.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rpg_claude/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads data and shows non-zero totals on Pregled',
      (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // After data loads, loading screen should be gone
    expect(find.text('Učitavanje podataka...'), findsNothing);

    // At least one number appears on screen (national total)
    expect(find.textContaining(RegExp(r'\d{3,}')), findsWidgets);
  });
}
