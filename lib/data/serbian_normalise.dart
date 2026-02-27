// ABOUTME: Strips Serbian diacritics and whitespace for fuzzy name matching.
// ABOUTME: Used to match municipality names across GeoJSON and CSV data sources.

/// Normalises a Serbian name by lowercasing, replacing diacritics with ASCII
/// equivalents, and stripping all whitespace.
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
