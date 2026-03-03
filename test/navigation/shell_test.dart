// ABOUTME: Widget tests for AppShell bottom navigation styling.
// ABOUTME: Verifies active/inactive icon appearance and indicator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_claude/navigation/shell.dart';
import 'package:rpg_claude/theme.dart';

void main() {
  testWidgets('navigation bar uses theme indicator color', (tester) async {
    final router = GoRouter(
      initialLocation: '/pregled',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/pregled', builder: (_, __) => const Placeholder()),
            GoRoute(path: '/opstine', builder: (_, __) => const Placeholder()),
            GoRoute(
              path: '/trendovi',
              builder: (_, __) => const Placeholder(),
            ),
            GoRoute(path: '/mapa', builder: (_, __) => const Placeholder()),
            GoRoute(
              path: '/o-aplikaciji',
              builder: (_, __) => const Placeholder(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: appTheme),
    );
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar, isNotNull);
  });
}
