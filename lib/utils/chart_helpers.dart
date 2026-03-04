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
