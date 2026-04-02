// ABOUTME: Orchestrates parallel fetching and parsing of all age structure CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'age_parser.dart';
import 'age_source.dart';
import 'data_source.dart';
import 'fetch_error.dart';
import 'models/age_record.dart';
import 'models/age_snapshot.dart';

class AgeLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws FetchException if all sources fail.
  static Future<List<AgeSnapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? AgeSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final errors = <FetchError>[];
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return AgeSnapshot(date: source.date, records: records);
      } on FetchException catch (e) {
        errors.add(e.error);
        return null;
      } on Exception catch (e) {
        errors.add(FetchError.classify(e));
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<AgeSnapshot>().toList();
    if (snapshots.isEmpty) {
      throw FetchException(_pickMostRelevantError(errors));
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  // Priority: noInternet > timeout > serverError > clientError > unknown
  static FetchError _pickMostRelevantError(List<FetchError> errors) {
    const priority = [
      FetchError.noInternet,
      FetchError.timeout,
      FetchError.serverError,
      FetchError.clientError,
      FetchError.unknown,
    ];
    for (final candidate in priority) {
      if (errors.contains(candidate)) return candidate;
    }
    return FetchError.unknown;
  }
}

// Top-level function required by compute().
List<AgeRecord> _parseInIsolate(List<int> bytes) {
  return AgeParser.parse(bytes);
}
