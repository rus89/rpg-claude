// ABOUTME: Serbian name utilities for fuzzy matching and display formatting.
// ABOUTME: Used to match municipality names across GeoJSON and CSV data sources.

/// Normalises a Serbian name by lowercasing, stripping or replacing diacritics,
/// and removing all whitespace.
///
/// đ and ? are both stripped rather than replaced, because the government CSV
/// data stores đ as a literal '?' character (data quality issue). Stripping
/// both ensures GeoJSON names (with đ) match CSV names (with ?).
String normaliseSerbianName(String name) {
  return name
      .toLowerCase()
      .replaceAll('š', 's')
      .replaceAll('đ', '')
      .replaceAll('?', '')
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('ž', 'z')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}

/// Converts a CamelCase GeoJSON municipality name into a readable display name
/// by inserting spaces before uppercase letters.
///
/// GeoJSON NAME_2 values have no spaces in compound names (e.g. "NovaVaroš").
/// This produces "Nova Varoš" for display.
final _camelBoundary = RegExp(r'(?<=[a-zšđčćž])(?=[A-ZŠĐČĆŽ])');

String displayName(String geoJsonName) {
  return geoJsonName.replaceAll(_camelBoundary, ' ');
}
