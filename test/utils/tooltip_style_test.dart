// ABOUTME: Tests for responsive tooltip sizing based on chart width and bar count.
// ABOUTME: Verifies font size scales down appropriately for smaller screens.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/utils/chart_helpers.dart';

void main() {
  group('tooltipFontSize', () {
    test('returns 11 for desktop-width chart with few bars', () {
      expect(tooltipFontSize(chartWidth: 800, barCount: 4), 11.0);
    });

    test('returns 9 for narrow chart with few bars', () {
      expect(tooltipFontSize(chartWidth: 350, barCount: 4), 9.0);
    });

    test('returns 7 for narrow chart with many bars', () {
      expect(tooltipFontSize(chartWidth: 350, barCount: 9), 7.0);
    });

    test('returns 9 for medium chart with many bars', () {
      expect(tooltipFontSize(chartWidth: 600, barCount: 9), 9.0);
    });

    test('never goes below 7', () {
      expect(tooltipFontSize(chartWidth: 200, barCount: 9), 7.0);
    });
  });

  group('showPermanentTooltips', () {
    test('true for desktop with few bars', () {
      expect(showPermanentTooltips(chartWidth: 800, barCount: 4), true);
    });

    test('true for mobile with few bars', () {
      expect(showPermanentTooltips(chartWidth: 350, barCount: 4), true);
    });

    test('false when bars too narrow for readable labels', () {
      expect(showPermanentTooltips(chartWidth: 250, barCount: 9), false);
    });
  });
}
