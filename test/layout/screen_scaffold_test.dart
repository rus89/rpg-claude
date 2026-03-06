// ABOUTME: Tests for the ScreenScaffold responsive wrapper.
// ABOUTME: Verifies mobile renders Scaffold+AppBar, desktop renders constrained body only.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/layout/screen_scaffold.dart';

Widget _buildAt(double width, {String title = 'Test', bool fullWidth = false}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp(
      home: ScreenScaffold(
        title: title,
        fullWidth: fullWidth,
        child: const Text('content'),
      ),
    ),
  );
}

void main() {
  group('mobile (< 1024px)', () {
    testWidgets('renders Scaffold with AppBar', (tester) async {
      await tester.pumpWidget(_buildAt(800));
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders no AppBar', (tester) async {
      await tester.pumpWidget(_buildAt(1200));
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('constrains content to max width', (tester) async {
      await tester.pumpWidget(_buildAt(1200));
      final boxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final hasMaxWidth = boxes.any((b) => b.constraints.maxWidth == 1200);
      expect(hasMaxWidth, isTrue);
    });

    testWidgets('fullWidth skips max-width constraint', (tester) async {
      await tester.pumpWidget(_buildAt(1200, fullWidth: true));
      final boxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final hasMaxWidth = boxes.any((b) => b.constraints.maxWidth == 1200);
      expect(hasMaxWidth, isFalse);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
