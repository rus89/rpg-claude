// ABOUTME: Tests for the responsive breakpoint infrastructure.
// ABOUTME: Verifies isDesktop returns correct values at breakpoint boundaries.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/layout/breakpoints.dart';

void main() {
  test('desktopBreakpoint is 1024', () {
    expect(desktopBreakpoint, equals(1024));
  });

  testWidgets('isDesktop returns false below 1024px', (tester) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1023, 800)),
        child: Builder(
          builder: (context) {
            result = isDesktop(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(result, isFalse);
  });

  testWidgets('isDesktop returns true at exactly 1024px', (tester) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1024, 800)),
        child: Builder(
          builder: (context) {
            result = isDesktop(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(result, isTrue);
  });

  testWidgets('isDesktop returns true above 1024px', (tester) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1440, 900)),
        child: Builder(
          builder: (context) {
            result = isDesktop(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(result, isTrue);
  });
}
