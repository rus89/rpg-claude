// ABOUTME: Widget tests for the O aplikaciji (about) screen.
// ABOUTME: Verifies disclaimer text and data source credit are present.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/screens/o_aplikaciji/o_aplikaciji_screen.dart';

void main() {
  testWidgets('shows disclaimer text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.textContaining('nezavisan'), findsWidgets);
  });

  testWidgets('shows data source credit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.textContaining('data.gov.rs'), findsWidgets);
  });

  testWidgets('info sections show leading icons', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.gavel), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('shows guide for all 4 main tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    await tester.scrollUntilVisible(find.text('Pregled'), 100);
    expect(find.text('Pregled'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Opštine'), 100);
    expect(find.text('Opštine'), findsOneWidget);
  });
}
