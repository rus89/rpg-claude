// ABOUTME: Classifies network fetch failures into user-actionable categories.
// ABOUTME: Each error type carries a Serbian message for display in the UI.

import 'dart:async';
import 'dart:io';

enum FetchError {
  noInternet('Nema internet konekcije. Povezite se na mrežu i pokušajte ponovo.'),
  timeout('Server ne odgovara. Proverite konekciju i pokušajte ponovo.'),
  serverError('Podaci trenutno nisu dostupni na serveru. Pokušajte ponovo kasnije.'),
  clientError('Izvor podataka nije pronađen. Pokušajte ponovo kasnije.'),
  unknown('Nije moguće učitati podatke. Proverite internet konekciju.');

  const FetchError(this.message);
  final String message;

  static FetchError classify(Object error) {
    if (error is SocketException) return FetchError.noInternet;
    if (error is TimeoutException) return FetchError.timeout;
    return FetchError.unknown;
  }

  static FetchError fromStatusCode(int statusCode) {
    if (statusCode >= 500) return FetchError.serverError;
    if (statusCode >= 400) return FetchError.clientError;
    return FetchError.unknown;
  }
}

class FetchException implements Exception {
  const FetchException(this.error);
  final FetchError error;

  @override
  String toString() => 'FetchException: ${error.message}';
}
