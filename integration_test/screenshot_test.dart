// ABOUTME: Integration test that captures Play Store screenshots by navigating real app state.
// ABOUTME: Must be run via `flutter drive` on a real emulator — not `flutter test`.

@Tags(['screenshot'])
library;

// Tagged 'screenshot' so bulk test runs can skip this file, which only works
// under `flutter drive` with a real emulator. To exclude during local
// `flutter test integration_test/`, pass `--exclude-tags=screenshot`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

    // Grab the GoRouter once from a descendant context (PregledScreen sits
    // inside the Router's InheritedGoRouter). The GoRouter instance is stable
    // for the app lifetime, so we keep the reference and reuse it across every
    // navigation below. MaterialApp itself can't be used — its own context
    // sits ABOVE the InheritedGoRouter provider and GoRouter.of would assert.
    final router = GoRouter.of(tester.element(find.byType(PregledScreen)));

    // 3. Switch the Flutter surface to image-capture mode. Must be called once,
    //    after the UI is stable, before any takeScreenshot.
    await binding.convertFlutterSurfaceToImage();

    // 4. Pregled (home) — already on it after redirect.
    await settleForScreenshot(tester);
    await binding.takeScreenshot('01_pregled');

    // Navigate via GoRouter rather than tapping the nav chrome. Mobile shows
    // a NavigationBar at the bottom; the tablet_10 viewport crosses the
    // 1024 dp desktop breakpoint in lib/layout/breakpoints.dart and shows an
    // AppBar with TextButtons instead. GoRouter works in both layouts.

    // 5. Opštine list.
    router.go('/opstine');
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
    router.push('/opstine/Novi Sad');
    await tester.pumpAndSettle();
    await settleForScreenshot(tester);
    await binding.takeScreenshot('03_opstina_detail');
    router.pop();
    await tester.pumpAndSettle();

    // 7. Trendovi.
    router.go('/trendovi');
    await tester.pumpAndSettle();
    await settleForScreenshot(tester);
    await binding.takeScreenshot('04_trendovi');

    // 8. Mapa — flutter_map tile loading never idles, so pumpAndSettle would
    //    hang. 15 s is sized for the largest tablet viewport.
    router.go('/mapa');
    await tester.pump(const Duration(milliseconds: 300));
    await Future.delayed(const Duration(seconds: 15));
    await settleForScreenshot(tester);
    await binding.takeScreenshot('05_mapa');
  });
}
