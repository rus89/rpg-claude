// ABOUTME: Tests for FetchError classification and Serbian error messages.
// ABOUTME: Verifies each error type maps to the correct user-facing message.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/fetch_error.dart';

void main() {
  group('FetchError.classify', () {
    test('classifies SocketException as noInternet', () {
      final error = FetchError.classify(
        const SocketException('No route to host'),
      );
      expect(error, FetchError.noInternet);
    });

    test('classifies TimeoutException as timeout', () {
      final error = FetchError.classify(TimeoutException('timed out'));
      expect(error, FetchError.timeout);
    });

    test('classifies generic Exception as unknown', () {
      final error = FetchError.classify(Exception('something'));
      expect(error, FetchError.unknown);
    });
  });

  group('FetchError.fromStatusCode', () {
    test('classifies 404 as clientError', () {
      expect(FetchError.fromStatusCode(404), FetchError.clientError);
    });

    test('classifies 500 as serverError', () {
      expect(FetchError.fromStatusCode(500), FetchError.serverError);
    });

    test('classifies 503 as serverError', () {
      expect(FetchError.fromStatusCode(503), FetchError.serverError);
    });
  });

  group('FetchError.message', () {
    test('noInternet message', () {
      expect(
        FetchError.noInternet.message,
        'Nema internet konekcije. Povezite se na mrežu i pokušajte ponovo.',
      );
    });

    test('timeout message', () {
      expect(
        FetchError.timeout.message,
        'Server ne odgovara. Proverite konekciju i pokušajte ponovo.',
      );
    });

    test('serverError message', () {
      expect(
        FetchError.serverError.message,
        'Podaci trenutno nisu dostupni na serveru. Pokušajte ponovo kasnije.',
      );
    });

    test('clientError message', () {
      expect(
        FetchError.clientError.message,
        'Izvor podataka nije pronađen. Pokušajte ponovo kasnije.',
      );
    });

    test('unknown message', () {
      expect(
        FetchError.unknown.message,
        'Nije moguće učitati podatke. Proverite internet konekciju.',
      );
    });
  });

  group('FetchException', () {
    test('stores error type', () {
      const ex = FetchException(FetchError.noInternet);
      expect(ex.error, FetchError.noInternet);
      expect(ex.toString(), contains('Nema internet konekcije'));
    });
  });
}
