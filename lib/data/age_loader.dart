// ABOUTME: Orchestrates parallel fetching and parsing of all age structure CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'age_parser.dart';
import 'age_source.dart';
import 'data_source.dart';
import 'models/age_record.dart';
import 'models/age_snapshot.dart';

class AgeLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws if all sources fail.
  static Future<List<AgeSnapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? AgeSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return AgeSnapshot(date: source.date, records: records);
      } on Exception {
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<AgeSnapshot>().toList();
    if (snapshots.isEmpty) {
      throw Exception('All age structure CSV sources failed to load');
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }
}

// Top-level function required by compute().
List<AgeRecord> _parseInIsolate(List<int> bytes) {
  return AgeParser.parse(bytes);
}
