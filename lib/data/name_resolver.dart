// ABOUTME: Maps CSV municipality names to canonical GeoJSON municipality names.
// ABOUTME: Handles diacritics corruption, spacing differences, and CamelCase splitting.

import 'serbian_normalise.dart';

class NameResolver {
  NameResolver(List<String> geoJsonNames) {
    for (final name in geoJsonNames) {
      _normalToGeoJson[normaliseSerbianName(name)] = name;
    }
    // Aliases for CSV names that are fundamentally different from GeoJSON names.
    // Maps normalised-cleaned-CSV-key → normalised-GeoJSON-key.
    for (final entry in _csvAliases.entries) {
      final geoJsonKey = entry.value;
      final geoJsonName = _normalToGeoJson[geoJsonKey];
      if (geoJsonName != null) {
        _normalToGeoJson[entry.key] = geoJsonName;
      }
    }
  }

  final _normalToGeoJson = <String, String>{};

  // CSV names where cleaning + normalisation is insufficient to match GeoJSON.
  // Key: normalised(cleaned(csvName)), Value: normalised(geoJsonName)
  static final _csvAliases = <String, String>{
    normaliseSerbianName('Ra?a Kragujeva?ka'): normaliseSerbianName('Rača'),
    normaliseSerbianName('Surcin'): normaliseSerbianName('Surčin'),
    normaliseSerbianName('Petrovac na Mlavi'): normaliseSerbianName('Petrovac'),
  };

  /// Returns the canonical GeoJSON name for a CSV municipality name,
  /// or null if no match.
  String? resolve(String csvName) {
    final cleaned = cleanCsvMunicipality(csvName);
    final key = normaliseSerbianName(cleaned);
    return _normalToGeoJson[key];
  }

  /// Returns a stable normalised key for grouping CSV records by municipality.
  /// Resolved names use the normalised GeoJSON name; unresolved names fall back
  /// to normalising the cleaned CSV name.
  String canonicalKey(String csvName) {
    final geoJson = resolve(csvName);
    if (geoJson != null) {
      return normaliseSerbianName(geoJson);
    }
    return normaliseSerbianName(cleanCsvMunicipality(csvName));
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
    final names =
        _normalToGeoJson.values.map(_splitCamelCase).toSet().toList()..sort();
    return names;
  }

  static final _camelBoundary = RegExp(r'(?<=[a-zšđčćž])(?=[A-ZŠĐČĆŽ])');

  static String _splitCamelCase(String name) {
    return name.replaceAll(_camelBoundary, ' ');
  }
}
