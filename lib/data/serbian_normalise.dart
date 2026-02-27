// ABOUTME: Strips Serbian diacritics and whitespace for fuzzy name matching.
// ABOUTME: Used to match municipality names across GeoJSON and CSV data sources.

/// Normalises a Serbian name by lowercasing, replacing diacritics with ASCII
/// equivalents, and stripping all whitespace.
String normaliseSerbianName(String name) {
  return name
      .toLowerCase()
      .replaceAll('š', 's')
      .replaceAll('đ', 'dj')
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('ž', 'z')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}
