// ABOUTME: Orchestrates parallel fetching and parsing of all RPG CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'csv_parser.dart';
import 'data_source.dart';
import 'models/record.dart';
import 'models/snapshot.dart';

class DataLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first.
  static Future<List<Snapshot>> loadAll() async {
    final futures = DataSource.sources.map((source) async {
      final bytes = await DataSource.fetchBytes(source.url);
      final records = await compute(_parseInIsolate, bytes);
      return buildSnapshot(source.date, records);
    });
    final snapshots = await Future.wait(futures);
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  static Snapshot buildSnapshot(DateTime date, List<Record> records) {
    return Snapshot(date: date, records: records);
  }
}

// Top-level function required by compute().
List<Record> _parseInIsolate(List<int> bytes) {
  return CsvParser.parse(bytes);
}
