// ABOUTME: Enum representing 10-year age brackets for farm operator age structure data.
// ABOUTME: Handles parsing from CSV labels including the Serbian locale "okt" bug.

enum AgeBracket {
  age10to19,
  age20to29,
  age30to39,
  age40to49,
  age50to59,
  age60to69,
  age70to79,
  age80to89,
  age90to99;

  /// Parses a CSV age label into an AgeBracket.
  /// Handles "10 - 19", "10-19", and "okt.19" (Serbian locale encodes 10 as
  /// "okt" = October abbreviation).
  static AgeBracket fromCsvLabel(String label) {
    final trimmed = label.trim().toLowerCase();

    // Serbian locale bug: "okt.19" means "10-19"
    if (trimmed == 'okt.19') return age10to19;

    // Strip spaces around the dash: "10 - 19" → "10-19"
    final normalized = trimmed.replaceAll(' ', '');

    return switch (normalized) {
      '10-19' => age10to19,
      '20-29' => age20to29,
      '30-39' => age30to39,
      '40-49' => age40to49,
      '50-59' => age50to59,
      '60-69' => age60to69,
      '70-79' => age70to79,
      '80-89' => age80to89,
      '90-99' => age90to99,
      _ => throw ArgumentError('Unknown age bracket label: "$label"'),
    };
  }

  String get displayName {
    final start = index * 10 + 10;
    final end = start + 9;
    return '$start\u2013$end';
  }

  double get midpoint => index * 10 + 14.5;
}
