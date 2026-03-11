// ABOUTME: Immutable container for all farm size records from one CSV snapshot.
// ABOUTME: Each snapshot corresponds to a single point-in-time data release.

import 'farm_size_record.dart';

class FarmSizeSnapshot {
  const FarmSizeSnapshot({required this.date, required this.records});

  final DateTime date;
  final List<FarmSizeRecord> records;
}
