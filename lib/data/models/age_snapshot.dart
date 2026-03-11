// ABOUTME: Immutable container for all age structure records from one CSV snapshot.
// ABOUTME: Each snapshot corresponds to a single point-in-time data release.

import 'age_record.dart';

class AgeSnapshot {
  const AgeSnapshot({required this.date, required this.records});

  final DateTime date;
  final List<AgeRecord> records;
}
