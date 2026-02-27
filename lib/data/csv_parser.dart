// ABOUTME: Parses raw bytes from an RPG CSV snapshot file into a list of Records.
// ABOUTME: Handles semicolon delimiter and UTF-8/Latin-1 encoding fallback.

import 'dart:convert';
import 'package:csv/csv.dart';
import 'models/org_form.dart';
import 'models/record.dart';

class CsvParser {
  // Returns an empty list if the bytes are empty or unparseable.
  static List<Record> parse(List<int> bytes) {
    if (bytes.isEmpty) return [];

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.length < 2) return [];

    // Skip header row (index 0)
    final records = <Record>[];
    for (final row in rows.skip(1)) {
      if (row.length < 8) continue;
      try {
        final orgFormCode = int.parse(row[4].toString().trim());
        final totalRegistered = int.parse(row[6].toString().trim());
        final activeHoldings = int.parse(row[7].toString().trim());
        records.add(Record(
          regionCode: row[0].toString().trim(),
          regionName: row[1].toString().trim(),
          municipalityCode: row[2].toString().trim(),
          municipalityName: row[3].toString().trim(),
          orgForm: OrgForm.fromCode(orgFormCode),
          totalRegistered: totalRegistered,
          activeHoldings: activeHoldings,
        ));
      } catch (_) {
        // Skip malformed rows silently
        continue;
      }
    }
    return records;
  }
}
