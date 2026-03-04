// ABOUTME: Maps CSV municipality names to canonical GeoJSON municipality names.
// ABOUTME: Handles diacritics corruption, spacing differences, and CamelCase splitting.

import 'serbian_normalise.dart';

class NameResolver {
  NameResolver(List<String> geoJsonNames) {
    for (final name in geoJsonNames) {
      _normalToGeoJson[normaliseSerbianName(name)] = name;
    }
  }

  final _normalToGeoJson = <String, String>{};

  /// Returns the canonical GeoJSON name for a CSV municipality name,
  /// or null if no match (e.g. aggregated entries like "Majdanpek/D.Milan44290").
  String? resolve(String csvName) {
    final key = normaliseSerbianName(csvName);
    return _normalToGeoJson[key];
  }

  /// Returns a human-readable display name for a CSV municipality name.
  /// Resolved names get CamelCase splitting; unresolved names are returned as-is.
  String displayName(String csvName) {
    final geoJson = resolve(csvName);
    if (geoJson != null) {
      return _splitCamelCase(geoJson);
    }
    return csvName;
  }

  /// All GeoJSON municipality names as display-ready strings, sorted.
  List<String> get allDisplayNames {
    final names = _normalToGeoJson.values.map(_splitCamelCase).toList()..sort();
    return names;
  }

  static final _camelBoundary =
      RegExp(r'(?<=[a-zšđčćž])(?=[A-ZŠĐČĆŽ])');

  static String _splitCamelCase(String name) {
    return name.replaceAll(_camelBoundary, ' ');
  }
}
