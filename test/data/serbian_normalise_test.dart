// ABOUTME: Tests for Serbian name normalisation used in municipality matching.
// ABOUTME: Covers diacritic stripping, whitespace removal, and corrupted đ handling.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/serbian_normalise.dart';

void main() {
  group('normaliseSerbianName', () {
    test('lowercases and strips whitespace', () {
      expect(normaliseSerbianName('Nova Varoš'), normaliseSerbianName('NovaVaroš'));
    });

    test('replaces š with s', () {
      expect(normaliseSerbianName('Šabac'), 'sabac');
    });

    test('replaces č with c', () {
      expect(normaliseSerbianName('Čačak'), 'cacak');
    });

    test('replaces ž with z', () {
      expect(normaliseSerbianName('Žabalj'), 'zabalj');
    });

    test('replaces ć with c', () {
      expect(normaliseSerbianName('Ćuprija'), 'cuprija');
    });

    test('strips đ', () {
      expect(normaliseSerbianName('Đurđevo'), 'urevo');
    });

    test('strips ? so corrupted đ matches', () {
      // CSV has literal '?' where đ should be
      expect(normaliseSerbianName('Žitora?a'), normaliseSerbianName('Žitorađa'));
    });

    test('matches GeoJSON "MaliIđoš" to CSV "Mali I?oš"', () {
      expect(normaliseSerbianName('MaliIđoš'), normaliseSerbianName('Mali I?oš'));
    });

    test('matches GeoJSON "Aranđelovac" to CSV "Aran?elovac"', () {
      expect(normaliseSerbianName('Aranđelovac'), normaliseSerbianName('Aran?elovac'));
    });

    test('matches GeoJSON "Inđija" to CSV "In?ija"', () {
      expect(normaliseSerbianName('Inđija'), normaliseSerbianName('In?ija'));
    });

    test('handles name with no diacritics unchanged', () {
      expect(normaliseSerbianName('Beograd'), 'beograd');
    });
  });
}
