// ABOUTME: Orchestrates parallel fetching and parsing of all farm size CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'data_source.dart';
import 'farm_size_parser.dart';
import 'farm_size_source.dart';
import 'models/farm_size_record.dart';
import 'models/farm_size_snapshot.dart';

class FarmSizeLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws if all sources fail.
  static Future<List<FarmSizeSnapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? FarmSizeSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return FarmSizeSnapshot(date: source.date, records: records);
      } on Exception {
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<FarmSizeSnapshot>().toList();
    if (snapshots.isEmpty) {
      throw Exception('All farm size CSV sources failed to load');
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }
}

// Top-level function required by compute().
List<FarmSizeRecord> _parseInIsolate(List<int> bytes) {
  return FarmSizeParser.parse(bytes);
}
