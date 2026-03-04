// ABOUTME: Serbian name utilities for fuzzy matching and display formatting.
// ABOUTME: Used to match municipality names across GeoJSON and CSV data sources.

/// Cleans a raw CSV municipality name before normalisation.
///
/// Splits on '/' and takes the first part (handles compound entries like
/// "Majdanpek/D.Milan44290"), then strips trailing " - grad" or " -grad"
/// suffixes (handles entries like "Novi Sad - grad").
final _gradSuffix = RegExp(r'\s*-\s*grad$', caseSensitive: false);

String cleanCsvMunicipality(String csvName) {
  var name = csvName.split('/').first.trim();
  name = name.replaceAll(_gradSuffix, '');
  return name;
}

/// Normalises a Serbian name by lowercasing, stripping diacritics and '?',
/// and removing all whitespace.
///
/// All Serbian diacritics (š, đ, č, ć, ž) and '?' are stripped rather than
/// replaced with base letters. The government CSV data stores various
/// diacritics as literal '?' characters (data quality issue). Stripping
/// both diacritics and '?' ensures GeoJSON names match CSV names regardless
/// of which characters were corrupted.
String normaliseSerbianName(String name) {
  return name
      .toLowerCase()
      .replaceAll('š', '')
      .replaceAll('đ', '')
      .replaceAll('?', '')
      .replaceAll('č', '')
      .replaceAll('ć', '')
      .replaceAll('ž', '')
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
