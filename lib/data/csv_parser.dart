// ABOUTME: Parses raw bytes from an RPG CSV snapshot file into a list of Records.
// ABOUTME: Uses header-based column mapping to handle variant column names across snapshots.

import 'dart:convert';
import 'package:csv/csv.dart';
import 'models/org_form.dart';
import 'models/record.dart';
import 'windows1250.dart';

class CsvParser {
  // Known column name variants, keyed by canonical name.
  // All comparisons are lowercase + trimmed.
  static const _columnVariants = <String, List<String>>{
    'regionCode': ['regija', 'sifregije'],
    'regionName': ['nazivregije'],
    'municipalityCode': ['sifraopstine'],
    'municipalityName': ['nazivopstinel'],
    'orgFormCode': ['orgoblik'],
    'totalRegistered': [
      'broj gazdinstava',
      'brojgazdinstavasva',
      'broj gazdinstava',
    ],
    'activeHoldings': [
      'aktivnagazdinstva',
      'brojgazdinstavaaktivna',
      'broj aktivnih gazdinstava',
      'broj aktivna gazdinstva',
    ],
  };

  static const _requiredColumns = [
    'regionCode',
    'municipalityName',
    'orgFormCode',
    'totalRegistered',
  ];

  /// Returns an empty list if the bytes are empty, unparseable, or missing
  /// required columns.
  static List<Record> parse(List<int> bytes) {
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

    final records = <Record>[];
    for (final row in rows.skip(1)) {
      try {
        final regionCode = _cell(row, columnMap['regionCode'])?.trim() ?? '';
        final regionName = _cell(row, columnMap['regionName'])?.trim() ?? '';
        final municipalityCode =
            _cell(row, columnMap['municipalityCode'])?.trim() ?? '';
        final municipalityName = _cell(
          row,
          columnMap['municipalityName'],
        )!.trim();
        final orgFormCode = int.parse(
          _cell(row, columnMap['orgFormCode'])!.trim(),
        );
        final totalRegistered = int.parse(
          _cell(row, columnMap['totalRegistered'])!.trim(),
        );

        final activeCell = _cell(row, columnMap['activeHoldings']);
        final activeHoldings = activeCell != null
            ? int.parse(activeCell.trim())
            : 0;

        records.add(
          Record(
            regionCode: regionCode,
            regionName: regionName,
            municipalityCode: municipalityCode,
            municipalityName: municipalityName,
            orgForm: OrgForm.fromCode(orgFormCode),
            totalRegistered: totalRegistered,
            activeHoldings: activeHoldings,
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
