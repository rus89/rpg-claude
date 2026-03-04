// ABOUTME: Tests for NameResolver that maps CSV municipality names to GeoJSON names.
// ABOUTME: Covers normalisation, resolution, display formatting, and unmatched entries.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/name_resolver.dart';

void main() {
  group('NameResolver', () {
    late NameResolver resolver;

    setUp(() {
      resolver = NameResolver([
        'Barajevo',
        'NovaVaroš',
        'MaloCrniće',
        'Medveđa',
        'Šabac',
        'Niš',
      ]);
    });

    test('resolves exact CSV name to GeoJSON name', () {
      expect(resolver.resolve('Barajevo'), 'Barajevo');
    });

    test('resolves CSV name with diacritics via normalisation', () {
      expect(resolver.resolve('Šabac'), 'Šabac');
    });

    test('resolves CSV name with ? (corrupted đ) to GeoJSON name', () {
      // CSV stores đ as ? — resolver should still match
      expect(resolver.resolve('Medve?a'), 'Medveđa');
    });

    test('resolves CSV name with spaces to CamelCase GeoJSON name', () {
      expect(resolver.resolve('Nova Varoš'), 'NovaVaroš');
    });

    test('returns null for aggregated/unmatched entries', () {
      expect(resolver.resolve('Majdanpek/D.Milan44290'), isNull);
    });

    test('displayName splits CamelCase for resolved names', () {
      expect(resolver.displayName('Nova Varoš'), 'Nova Varoš');
    });

    test('displayName returns cleaned-up raw name for unmatched', () {
      final name = resolver.displayName('Majdanpek/D.Milan44290');
      expect(name, 'Majdanpek/D.Milan44290');
    });

    test('displayName for simple resolved name', () {
      expect(resolver.displayName('Barajevo'), 'Barajevo');
    });

    test(
      'allDisplayNames returns sorted list of all GeoJSON display names',
      () {
        final names = resolver.allDisplayNames;
        expect(names.length, 6);
        expect(names.first, 'Barajevo');
        // CamelCase split
        expect(names.contains('Nova Varoš'), isTrue);
        expect(names.contains('Malo Crniće'), isTrue);
        expect(names.contains('Medveđa'), isTrue);
      },
    );
  });
}
