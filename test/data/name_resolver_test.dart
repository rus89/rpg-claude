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
        'NoviSad',
        'Kragujevac',
        'Majdanpek',
        'Lučani',
        'Rača',
        'Surčin',
        'Petrovac',
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

    group('cleaning — strips suffixes and compound entries', () {
      test('resolves "Novi Sad - grad" via cleaning', () {
        expect(resolver.resolve('Novi Sad - grad'), 'NoviSad');
      });

      test('resolves "Kragujevac - grad" via cleaning', () {
        expect(resolver.resolve('Kragujevac - grad'), 'Kragujevac');
      });

      test('resolves "Niš -grad" via cleaning', () {
        expect(resolver.resolve('Niš -grad'), 'Niš');
      });

      test('resolves "Majdanpek/D.Milan44290" via cleaning', () {
        expect(resolver.resolve('Majdanpek/D.Milan44290'), 'Majdanpek');
      });

      test('resolves "Lu?ani /Gu?a 41302" via cleaning', () {
        expect(resolver.resolve('Lu?ani /Gu?a 41302'), 'Lučani');
      });
    });

    group('aliases — fundamentally different names', () {
      test('resolves "Ra?a Kragujeva?ka" to Rača via alias', () {
        expect(resolver.resolve('Ra?a Kragujeva?ka'), 'Rača');
      });

      test('resolves "Surcin" to Surčin via alias', () {
        expect(resolver.resolve('Surcin'), 'Surčin');
      });

      test('resolves "Petrovac na Mlavi" to Petrovac via alias', () {
        expect(resolver.resolve('Petrovac na Mlavi'), 'Petrovac');
      });
    });

    group('canonicalKey', () {
      test('same key for "Novi Sad - grad" and "Novi Sad"', () {
        expect(
          resolver.canonicalKey('Novi Sad - grad'),
          resolver.canonicalKey('Novi Sad'),
        );
      });

      test('same key for "Surcin" and "Surčin"', () {
        expect(
          resolver.canonicalKey('Surcin'),
          resolver.canonicalKey('Surčin'),
        );
      });

      test('same key for "Ra?a Kragujeva?ka" and "Rača"', () {
        expect(
          resolver.canonicalKey('Ra?a Kragujeva?ka'),
          resolver.canonicalKey('Rača'),
        );
      });

      test('returns normalised GeoJSON name when resolved', () {
        // "Barajevo" resolves to GeoJSON "Barajevo", normalised = "barajevo"
        expect(resolver.canonicalKey('Barajevo'), 'barajevo');
      });

      test('falls back to normalised cleaned name when unresolved', () {
        // Unknown name, not in GeoJSON — falls back
        expect(resolver.canonicalKey('UnknownPlace'), 'unknownplace');
      });
    });

    test('displayName splits CamelCase for resolved names', () {
      expect(resolver.displayName('Nova Varoš'), 'Nova Varoš');
    });

    test('displayName returns raw name for unmatched', () {
      final name = resolver.displayName('TotallyUnknown');
      expect(name, 'TotallyUnknown');
    });

    test('displayName for simple resolved name', () {
      expect(resolver.displayName('Barajevo'), 'Barajevo');
    });

    test('allDisplayNames returns sorted deduplicated list', () {
      final names = resolver.allDisplayNames;
      // 13 GeoJSON names + 3 aliases, but aliases point to existing
      // GeoJSON entries, so .toSet() deduplicates them → 13
      expect(names.length, 13);
      expect(names.first, 'Barajevo');
      expect(names.contains('Nova Varoš'), isTrue);
      expect(names.contains('Malo Crniće'), isTrue);
      expect(names.contains('Medveđa'), isTrue);
      expect(names.contains('Novi Sad'), isTrue);
      expect(names.contains('Rača'), isTrue);
      // No duplicates from aliases
      expect(names.where((n) => n == 'Rača').length, 1);
    });
  });
}
