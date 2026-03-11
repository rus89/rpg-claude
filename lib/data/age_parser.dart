// ABOUTME: Parses raw bytes from an age structure CSV snapshot into a list of AgeRecords.
// ABOUTME: Uses header-based column mapping to handle variant column names across snapshots.

import 'dart:convert';
import 'package:csv/csv.dart';
import 'models/age_bracket.dart';
import 'models/age_record.dart';
import 'windows1250.dart';

class AgeParser {
  static const _columnVariants = <String, List<String>>{
    'regionCode': ['regija', 'sifregije'],
    'municipalityCode': ['sifraopstine'],
    'municipalityName': ['nazivopstinel'],
    'ageBracket': ['birthrange', 'opseg godina', 'opseggodina'],
    'farmCount': ['brojdomacinstva', 'brojpg', 'broj domacinstva', 'broj pg'],
  };

  static const _requiredColumns = [
    'municipalityName',
    'ageBracket',
    'farmCount',
  ];

  /// Returns an empty list if the bytes are empty, unparseable, or missing
  /// required columns.
  static List<AgeRecord> parse(List<int> bytes) {
    if (bytes.isEmpty) return [];

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = windows1250Decode(bytes);
    }

    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.length < 2) return [];

    final columnMap = _buildColumnMap(rows.first);
    for (final required in _requiredColumns) {
      if (!columnMap.containsKey(required)) return [];
    }

    final records = <AgeRecord>[];
    for (final row in rows.skip(1)) {
      try {
        final municipalityName = _cell(
          row,
          columnMap['municipalityName'],
        )!.trim();
        if (municipalityName.isEmpty) continue;

        final ageBracket = AgeBracket.fromCsvLabel(
          _cell(row, columnMap['ageBracket'])!.trim(),
        );
        final farmCount = int.parse(_cell(row, columnMap['farmCount'])!.trim());

        records.add(
          AgeRecord(
            regionCode: _cell(row, columnMap['regionCode'])?.trim() ?? '',
            municipalityCode:
                _cell(row, columnMap['municipalityCode'])?.trim() ?? '',
            municipalityName: municipalityName,
            ageBracket: ageBracket,
            farmCount: farmCount,
          ),
        );
      } on FormatException catch (_) {
        continue;
      } on ArgumentError catch (_) {
        continue;
      }
    }
    return records;
  }

  /// Maps canonical column names to their 0-based index in the header row.
  static Map<String, int> _buildColumnMap(List<dynamic> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final normalized = headerRow[i].toString().trim().toLowerCase();
      for (final entry in _columnVariants.entries) {
        if (entry.value.contains(normalized)) {
          map[entry.key] = i;
          break;
        }
      }
    }
    return map;
  }

  /// Returns the string value at [index] in [row], or null if index is null
  /// or out of range.
  static String? _cell(List<dynamic> row, int? index) {
    if (index == null || index >= row.length) return null;
    return row[index].toString();
  }
}
