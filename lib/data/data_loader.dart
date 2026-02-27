// ABOUTME: Orchestrates parallel fetching and parsing of all RPG CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'csv_parser.dart';
import 'data_source.dart';
import 'models/record.dart';
import 'models/snapshot.dart';

class DataLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws if all sources fail.
  static Future<List<Snapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? DataSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return buildSnapshot(source.date, records);
      } on Exception {
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<Snapshot>().toList();
    if (snapshots.isEmpty) {
      throw Exception('All CSV sources failed to load');
    }
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
