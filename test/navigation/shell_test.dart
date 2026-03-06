// ABOUTME: Tests for AppShell responsive navigation.
// ABOUTME: Verifies bottom nav on mobile and top AppBar nav on desktop.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_claude/navigation/shell.dart';
import 'package:rpg_claude/theme.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/pregled',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/pregled', builder: (_, __) => const Placeholder()),
          GoRoute(path: '/opstine', builder: (_, __) => const Placeholder()),
          GoRoute(path: '/trendovi', builder: (_, __) => const Placeholder()),
          GoRoute(path: '/mapa', builder: (_, __) => const Placeholder()),
          GoRoute(
            path: '/o-aplikaciji',
            builder: (_, __) => const Placeholder(),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('mobile (< 1024px)', () {
    testWidgets('renders bottom NavigationBar', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: appTheme),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('does not render top AppBar', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: appTheme),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders top AppBar with app title', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: appTheme),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(
        find.text('Registrovana Poljoprivredna Gazdinstva Srbije'),
        findsOneWidget,
      );
    });

    testWidgets('does not render bottom NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: appTheme),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('renders navigation text buttons', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: appTheme),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pregled'), findsOneWidget);
      expect(find.text('Opštine'), findsOneWidget);
      expect(find.text('Trendovi'), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('O aplikaciji'), findsOneWidget);
    });
  });
}
