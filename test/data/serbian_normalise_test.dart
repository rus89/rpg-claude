// ABOUTME: Tests for Serbian name normalisation used in municipality matching.
// ABOUTME: Covers diacritic stripping, whitespace removal, and corrupted character handling.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/serbian_normalise.dart';

void main() {
  group('normaliseSerbianName', () {
    test('lowercases and strips whitespace', () {
      expect(
        normaliseSerbianName('Nova Varoš'),
        normaliseSerbianName('NovaVaroš'),
      );
    });

    test('strips š', () {
      expect(normaliseSerbianName('Šabac'), 'abac');
    });

    test('strips č', () {
      expect(normaliseSerbianName('Čačak'), 'aak');
    });

    test('strips ž', () {
      expect(normaliseSerbianName('Žabalj'), 'abalj');
    });

    test('strips ć', () {
      expect(normaliseSerbianName('Ćuprija'), 'uprija');
    });

    test('strips đ', () {
      expect(normaliseSerbianName('Đurđevo'), 'urevo');
    });

    test('strips ? so corrupted diacritics match', () {
      // CSV has literal '?' where diacritics should be
      expect(
        normaliseSerbianName('Žitora?a'),
        normaliseSerbianName('Žitorađa'),
      );
    });

    test('matches CSV "?a?ak" to GeoJSON "Čačak"', () {
      expect(normaliseSerbianName('?a?ak'), normaliseSerbianName('Čačak'));
    });

    test('matches GeoJSON "MaliIđoš" to CSV "Mali I?oš"', () {
      expect(
        normaliseSerbianName('MaliIđoš'),
        normaliseSerbianName('Mali I?oš'),
      );
    });

    test('matches GeoJSON "Aranđelovac" to CSV "Aran?elovac"', () {
      expect(
        normaliseSerbianName('Aranđelovac'),
        normaliseSerbianName('Aran?elovac'),
      );
    });

    test('matches GeoJSON "Inđija" to CSV "In?ija"', () {
      expect(normaliseSerbianName('Inđija'), normaliseSerbianName('In?ija'));
    });

    test('handles name with no diacritics unchanged', () {
      expect(normaliseSerbianName('Beograd'), 'beograd');
    });
  });

  group('cleanCsvMunicipality', () {
    test('strips " - grad" suffix', () {
      expect(cleanCsvMunicipality('Novi Sad - grad'), 'Novi Sad');
    });

    test('strips " -grad" suffix (no leading space before dash)', () {
      expect(cleanCsvMunicipality('Niš -grad'), 'Niš');
    });

    test('splits on "/" and takes first part, trimmed', () {
      expect(cleanCsvMunicipality('Majdanpek/D.Milan44290'), 'Majdanpek');
    });

    test('splits on "/" with spaces and takes first part, trimmed', () {
      expect(cleanCsvMunicipality('Lu?ani /Gu?a 41302'), 'Lu?ani');
    });

    test('leaves normal names unchanged', () {
      expect(cleanCsvMunicipality('Barajevo'), 'Barajevo');
    });

    test('handles both slash and grad suffix', () {
      // Split on "/" first, then strip " - grad" from the result
      expect(cleanCsvMunicipality('Foo - grad/Bar'), 'Foo');
    });
  });

  group('displayName', () {
    test('inserts spaces into CamelCase GeoJSON names', () {
      expect(displayName('NovaVaroš'), 'Nova Varoš');
      expect(displayName('BajinaBašta'), 'Bajina Bašta');
      expect(displayName('NoviBeograd'), 'Novi Beograd');
      expect(displayName('GadžinHan'), 'Gadžin Han');
      expect(displayName('MaloCrniće'), 'Malo Crniće');
      expect(displayName('MaliIđoš'), 'Mali Iđoš');
    });

    test('leaves single-word names unchanged', () {
      expect(displayName('Niš'), 'Niš');
      expect(displayName('Barajevo'), 'Barajevo');
      expect(displayName('Čačak'), 'Čačak');
    });
  });
}
