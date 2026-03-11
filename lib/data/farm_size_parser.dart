// ABOUTME: Parses raw bytes from a farm size CSV snapshot into a list of FarmSizeRecords.
// ABOUTME: Uses header-based column mapping to handle variant column names across snapshots.

import 'dart:convert';
import 'package:csv/csv.dart';
import 'models/farm_size_record.dart';
import 'windows1250.dart';

class FarmSizeParser {
  static const _columnVariants = <String, List<String>>{
    'regionCode': ['regija', 'sifregije'],
    'regionName': ['nazivregije'],
    'municipalityCode': ['sifraopstine'],
    'municipalityName': ['nazivopstinel'],
    'countUpTo5': ['broj pg <=5', 'broj pg <= 5'],
    'areaUpTo5': ['povrsina ukupno <=5', 'povrsina ukupno <= 5'],
    'count5to20': ['broj pg 5-20', 'broj pg 5 - 20'],
    'area5to20': ['povrsina ukupno 5-20', 'povrsina ukupno 5 - 20'],
    'count20to100': ['broj pg 20-100', 'broj pg 20 - 100'],
    'area20to100': ['povrsina ukupno 20-100', 'povrsina ukupno 20 - 100'],
    'countOver100': ['broj pg >100', 'broj pg > 100'],
    'areaOver100': ['povrsina ukupno >100', 'povrsina ukupno > 100'],
  };

  static const _requiredColumns = [
    'municipalityName',
    'countUpTo5',
    'areaUpTo5',
    'count5to20',
    'area5to20',
    'count20to100',
    'area20to100',
    'countOver100',
    'areaOver100',
  ];

  /// Returns an empty list if the bytes are empty, unparseable, or missing
  /// required columns.
  static List<FarmSizeRecord> parse(List<int> bytes) {
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

    final records = <FarmSizeRecord>[];
    for (final row in rows.skip(1)) {
      try {
        final municipalityName = _cell(
          row,
          columnMap['municipalityName'],
        )!.trim();
        if (municipalityName.isEmpty) continue;

        records.add(
          FarmSizeRecord(
            regionCode: _cell(row, columnMap['regionCode'])?.trim() ?? '',
            regionName: _cell(row, columnMap['regionName'])?.trim() ?? '',
            municipalityCode:
                _cell(row, columnMap['municipalityCode'])?.trim() ?? '',
            municipalityName: municipalityName,
            countUpTo5: _parseInt(_cell(row, columnMap['countUpTo5'])!),
            areaUpTo5: _parseDecimal(_cell(row, columnMap['areaUpTo5'])!),
            count5to20: _parseInt(_cell(row, columnMap['count5to20'])!),
            area5to20: _parseDecimal(_cell(row, columnMap['area5to20'])!),
            count20to100: _parseInt(_cell(row, columnMap['count20to100'])!),
            area20to100: _parseDecimal(_cell(row, columnMap['area20to100'])!),
            countOver100: _parseInt(_cell(row, columnMap['countOver100'])!),
            areaOver100: _parseDecimal(_cell(row, columnMap['areaOver100'])!),
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

  /// Parses Serbian decimal format: strips dot thousands separators,
  /// replaces comma decimal separator with period.
  static double _parseDecimal(String raw) {
    final trimmed = raw.trim();
    if (trimmed == '-' || trimmed.isEmpty) return 0;
    final normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
    return double.parse(normalized);
  }

  static int _parseInt(String raw) {
    final trimmed = raw.trim();
    if (trimmed == '-' || trimmed.isEmpty) return 0;
    return int.parse(trimmed.replaceAll('.', ''));
  }
}
