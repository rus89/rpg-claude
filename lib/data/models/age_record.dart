// ABOUTME: Immutable data model for one municipality x age bracket row.
// ABOUTME: Stores the farm operator count for a single age bracket in a single municipality.

import 'age_bracket.dart';

class AgeRecord {
  const AgeRecord({
    required this.regionCode,
    required this.municipalityCode,
    required this.municipalityName,
    required this.ageBracket,
    required this.farmCount,
  });

  final String regionCode;
  final String municipalityCode;
  final String municipalityName;
  final AgeBracket ageBracket;
  final int farmCount;
}
