// ABOUTME: Tests for the centralised app theme.
// ABOUTME: Verifies color scheme, card, and app bar theme values.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/theme.dart';

void main() {
  test('primary color is olive green', () {
    expect(
      appTheme.colorScheme.primary.toARGB32(),
      equals(const Color(0xFF5C7A45).toARGB32()),
    );
  });

  test('scaffold background is warm cream', () {
    expect(
      appTheme.scaffoldBackgroundColor.toARGB32(),
      equals(const Color(0xFFF5F2EC).toARGB32()),
    );
  });

  test('app bar uses primary color background with white foreground', () {
    expect(
      appTheme.appBarTheme.backgroundColor!.toARGB32(),
      equals(const Color(0xFF5C7A45).toARGB32()),
    );
    expect(
      appTheme.appBarTheme.foregroundColor!.toARGB32(),
      equals(const Color(0xFFFFFFFF).toARGB32()),
    );
  });

  test('card theme has 12px border radius', () {
    final shape = appTheme.cardTheme.shape as RoundedRectangleBorder;
    final radius = (shape.borderRadius as BorderRadius).topLeft;
    expect(radius.x, equals(12));
  });

  test('cardDecoration has 12px radius and subtle shadow', () {
    expect(cardDecoration.borderRadius, equals(BorderRadius.circular(12)));
    expect(cardDecoration.color, equals(const Color(0xFFFFFFFF)));
    expect(cardDecoration.boxShadow, hasLength(1));
    final shadow = cardDecoration.boxShadow!.single;
    expect(shadow.color, equals(const Color(0x0F000000)));
    expect(shadow.blurRadius, equals(8));
    expect(shadow.offset, equals(const Offset(0, 2)));
  });
}
