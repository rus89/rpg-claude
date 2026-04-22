// ABOUTME: Integration test that captures Play Store screenshots by navigating real app state.
// ABOUTME: Must be run via `flutter drive` on a real emulator — not `flutter test`.

@Tags(['screenshot'])
library;

// Tagged 'screenshot' so bulk test runs can skip this file, which only works
// under `flutter drive` with a real emulator. To exclude during local
// `flutter test integration_test/`, pass `--exclude-tags=screenshot`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rpg_claude/main.dart' as app;
import 'package:rpg_claude/screens/pregled/pregled_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Ensure a frame is rasterized into FlutterImageView before each takeScreenshot.
  // Without this, takeScreenshot blocks its RPC reply waiting for a frame that
  // never arrives. Do NOT inline — every screenshot call needs it.
  Future<void> settleForScreenshot(WidgetTester tester) async {
    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pump();
  }

  testWidgets('capture Play Store screenshots', (tester) async {
    // Note: /o-aplikaciji (info) tab is intentionally NOT captured — About
    // screens rarely perform well as Play Store marketing material.

    // Scope icon lookups to the bottom NavigationBar so future icon reuse
    // inside any screen can't accidentally match a tap target.
    Finder navIcon(IconData icon) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(icon),
    );

    // 1. Launch the real app. Do NOT await — app.main() calls runApp() which
    //    never returns; awaiting hangs the test forever.
    app.main();

    // 2. Wait until the home-screen anchor widget is in the tree.
    //    Do NOT use bare pumpAndSettle() here — loading spinners keep the tree
    //    busy and pumpAndSettle will throw a timeout error.
    var found = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 2));
      if (find.byType(PregledScreen).evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
    if (!found) {
      fail(
        'Home-screen anchor not found after 60 seconds — is the API reachable?',
      );
    }

    // 3. Switch the Flutter surface to image-capture mode. Must be called once,
    //    after the UI is stable, before any takeScreenshot.
    await binding.convertFlutterSurfaceToImage();

    // 4. Pregled (home) — already on it after redirect.
    await settleForScreenshot(tester);
    await binding.takeScreenshot('01_pregled');

    // 5. Opštine list — bottom-nav Icons.list.
    await tester.tap(navIcon(Icons.list));
    await tester.pumpAndSettle();
    await settleForScreenshot(tester);
    await binding.takeScreenshot('02_opstine');

    expect(
      find.byType(ListTile),
      findsWidgets,
      reason: 'Municipality list must not be empty — check data.gov.rs',
    );

    // 6. Opština detail — pin "Novi Sad" as the showcase. Alphabetical first
    //    would be "Ada", a weak ambassador for a Play Store screenshot.
    //    ListView is lazy, so scroll the tile into view before tapping.
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Novi Sad'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Novi Sad'));
    await tester.pumpAndSettle();
    await settleForScreenshot(tester);
    await binding.takeScreenshot('03_opstina_detail');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 7. Trendovi — bottom-nav Icons.show_chart.
    await tester.tap(navIcon(Icons.show_chart));
    await tester.pumpAndSettle();
    await settleForScreenshot(tester);
    await binding.takeScreenshot('04_trendovi');

    // 8. Mapa — flutter_map tile loading never idles, so pumpAndSettle would
    //    hang. 15 s is sized for the largest tablet viewport.
    await tester.tap(navIcon(Icons.map));
    await tester.pump(const Duration(milliseconds: 300));
    await Future.delayed(const Duration(seconds: 15));
    await settleForScreenshot(tester);
    await binding.takeScreenshot('05_mapa');
  });
}
