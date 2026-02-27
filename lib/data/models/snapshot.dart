// ABOUTME: Immutable container for all records from one RPG CSV snapshot file.
// ABOUTME: Each snapshot corresponds to a single point-in-time data release.

import 'record.dart';

class Snapshot {
  const Snapshot({
    required this.date,
    required this.records,
  });

  final DateTime date;
  final List<Record> records;
}
