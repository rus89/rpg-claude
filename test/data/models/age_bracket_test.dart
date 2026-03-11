// ABOUTME: Tests for AgeBracket enum parsing, display names, and midpoints.
// ABOUTME: Covers standard CSV labels, Serbian locale "okt.19" bug, and error cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/age_bracket.dart';

void main() {
  group('AgeBracket.fromCsvLabel', () {
    test('parses standard format with spaces "10 - 19"', () {
      expect(AgeBracket.fromCsvLabel('10 - 19'), AgeBracket.age10to19);
      expect(AgeBracket.fromCsvLabel('20 - 29'), AgeBracket.age20to29);
      expect(AgeBracket.fromCsvLabel('30 - 39'), AgeBracket.age30to39);
      expect(AgeBracket.fromCsvLabel('40 - 49'), AgeBracket.age40to49);
      expect(AgeBracket.fromCsvLabel('50 - 59'), AgeBracket.age50to59);
      expect(AgeBracket.fromCsvLabel('60 - 69'), AgeBracket.age60to69);
      expect(AgeBracket.fromCsvLabel('70 - 79'), AgeBracket.age70to79);
      expect(AgeBracket.fromCsvLabel('80 - 89'), AgeBracket.age80to89);
      expect(AgeBracket.fromCsvLabel('90 - 99'), AgeBracket.age90to99);
    });

    test('parses compact format without spaces "10-19"', () {
      expect(AgeBracket.fromCsvLabel('10-19'), AgeBracket.age10to19);
      expect(AgeBracket.fromCsvLabel('20-29'), AgeBracket.age20to29);
      expect(AgeBracket.fromCsvLabel('30-39'), AgeBracket.age30to39);
      expect(AgeBracket.fromCsvLabel('40-49'), AgeBracket.age40to49);
      expect(AgeBracket.fromCsvLabel('50-59'), AgeBracket.age50to59);
      expect(AgeBracket.fromCsvLabel('60-69'), AgeBracket.age60to69);
      expect(AgeBracket.fromCsvLabel('70-79'), AgeBracket.age70to79);
      expect(AgeBracket.fromCsvLabel('80-89'), AgeBracket.age80to89);
      expect(AgeBracket.fromCsvLabel('90-99'), AgeBracket.age90to99);
    });

    test('parses Serbian locale bug "okt.19" as 10-19', () {
      expect(AgeBracket.fromCsvLabel('okt.19'), AgeBracket.age10to19);
    });

    test('throws ArgumentError for unrecognized label', () {
      expect(() => AgeBracket.fromCsvLabel('foo'), throwsArgumentError);
      expect(() => AgeBracket.fromCsvLabel(''), throwsArgumentError);
      expect(() => AgeBracket.fromCsvLabel('100 - 109'), throwsArgumentError);
    });
  });

  group('AgeBracket.displayName', () {
    test('uses en-dash separator for all brackets', () {
      expect(AgeBracket.age10to19.displayName, '10\u201319');
      expect(AgeBracket.age20to29.displayName, '20\u201329');
      expect(AgeBracket.age30to39.displayName, '30\u201339');
      expect(AgeBracket.age40to49.displayName, '40\u201349');
      expect(AgeBracket.age50to59.displayName, '50\u201359');
      expect(AgeBracket.age60to69.displayName, '60\u201369');
      expect(AgeBracket.age70to79.displayName, '70\u201379');
      expect(AgeBracket.age80to89.displayName, '80\u201389');
      expect(AgeBracket.age90to99.displayName, '90\u201399');
    });
  });

  group('AgeBracket.midpoint', () {
    test('returns midpoint of each bracket', () {
      expect(AgeBracket.age10to19.midpoint, 14.5);
      expect(AgeBracket.age20to29.midpoint, 24.5);
      expect(AgeBracket.age30to39.midpoint, 34.5);
      expect(AgeBracket.age40to49.midpoint, 44.5);
      expect(AgeBracket.age50to59.midpoint, 54.5);
      expect(AgeBracket.age60to69.midpoint, 64.5);
      expect(AgeBracket.age70to79.midpoint, 74.5);
      expect(AgeBracket.age80to89.midpoint, 84.5);
      expect(AgeBracket.age90to99.midpoint, 94.5);
    });
  });
}
