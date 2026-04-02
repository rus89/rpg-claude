// ABOUTME: Shared chart formatting utilities for line and bar charts.
// ABOUTME: Provides count abbreviation, date-to-x-value conversion, and date labels.

import 'package:intl/intl.dart';

/// Abbreviates a count for y-axis labels: 1500 → "1,5K", 1200000 → "1,2M".
String abbreviateCount(num value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')}K';
  }
  return value.toInt().toString();
}

/// Converts a date to a proportional x-axis value (milliseconds since epoch).
double dateToX(DateTime date) => date.millisecondsSinceEpoch.toDouble();

/// Formats a date for chart axis labels.
String formatDateLabel(DateTime date) => DateFormat('MM/yy').format(date);

/// Calculates tooltip font size based on available chart width and bar count.
/// Scales down for narrower charts with more bars to prevent overlap.
double tooltipFontSize({required double chartWidth, required int barCount}) {
  final barWidth = barCount > 0 ? chartWidth / barCount : chartWidth;
  if (barWidth >= 100) return 11.0;
  if (barWidth >= 50) return 9.0;
  return 7.0;
}

/// Whether to show permanent tooltip labels above bars.
/// Returns false when bars are too narrow for readable labels — in that case
/// the chart should use tap-to-show tooltips instead.
bool showPermanentTooltips({
  required double chartWidth,
  required int barCount,
}) {
  final barWidth = barCount > 0 ? chartWidth / barCount : chartWidth;
  return barWidth >= 30;
}
