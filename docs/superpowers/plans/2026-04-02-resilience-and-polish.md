# Resilience & Polish — Update 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> Read and follow all rules in CLAUDE.md at the project root before starting any work.

**Goal:** Make the app handle real-world conditions (bad network, partial failures, small screens) gracefully, improving quality before Google Play production submission.

**Architecture:** Introduce a `FetchError` enum that classifies network failures by type. Propagate this through loaders so the UI can show specific Serbian error messages. Add `RefreshIndicator` to scrollable screens that retries only failed providers. Fix bar chart tooltip sizing to scale with available width. Replace silent `SizedBox.shrink()` error states with visible "nema podataka" messages and retry actions.

**Tech Stack:** Flutter, Riverpod (code-generated), fl_chart, http, GoRouter — all existing dependencies. No new packages.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/data/fetch_error.dart` | `FetchError` enum + `FetchException` class wrapping error type |
| Modify | `lib/data/data_source.dart:79-85` | Classify HTTP errors and catch `SocketException`/`TimeoutException` in `fetchBytes` |
| Modify | `lib/data/data_loader.dart:20-27` | Propagate `FetchException` instead of silently swallowing; collect error types |
| Modify | `lib/data/farm_size_loader.dart:21-27` | Same pattern as DataLoader |
| Modify | `lib/data/age_loader.dart:21-27` | Same pattern as AgeLoader |
| Modify | `lib/screens/loading/loading_screen.dart` | Show specific error messages based on `FetchException` type; retry button |
| Modify | `lib/screens/pregled/pregled_screen.dart:150,278` | Replace `SizedBox.shrink()` on error with visible message + retry |
| Modify | `lib/screens/pregled/pregled_screen.dart` | Wrap `SingleChildScrollView` with `RefreshIndicator` |
| Modify | `lib/screens/opstine/opstina_detail_screen.dart:223,328` | Replace `SizedBox.shrink()` on error with visible message + retry |
| Modify | `lib/screens/opstine/opstina_detail_screen.dart` | Wrap body with `RefreshIndicator` |
| Modify | `lib/screens/trendovi/trendovi_screen.dart` | Wrap body with `RefreshIndicator` |
| Modify | `lib/screens/mapa/mapa_screen.dart:730-736,886-893` | Already has error text — update to be more specific |
| Modify | `lib/utils/chart_helpers.dart` | Add `tooltipStyle` helper that computes font size + padding from bar count and chart width |
| Modify | `lib/screens/pregled/pregled_screen.dart:350-371,459-477` | Use `tooltipStyle` helper |
| Modify | `lib/screens/opstine/opstina_detail_screen.dart:250-302,356-407` | Add tooltip config using `tooltipStyle` |
| Create | `test/data/fetch_error_test.dart` | Tests for FetchError classification |
| Modify | `test/data/data_loader_test.dart` | Tests for error propagation |
| Modify | `test/screens/loading_screen_test.dart` | Tests for specific error messages |
| Modify | `test/screens/pregled_screen_test.dart` | Tests for visible error states + pull-to-refresh |
| Modify | `test/screens/opstina_detail_screen_test.dart` | Tests for visible error states |
| Create | `test/utils/tooltip_style_test.dart` | Tests for responsive tooltip sizing |

---

## Task 1: FetchError enum and FetchException

**Files:**
- Create: `lib/data/fetch_error.dart`
- Create: `test/data/fetch_error_test.dart`

- [ ] **Step 1: Write the failing test for FetchError classification**

```dart
// test/data/fetch_error_test.dart
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
      final ex = FetchException(FetchError.noInternet);
      expect(ex.error, FetchError.noInternet);
      expect(ex.toString(), contains('Nema internet konekcije'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/fetch_error_test.dart`
Expected: FAIL — `package:rpg_claude/data/fetch_error.dart` does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/fetch_error.dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/fetch_error_test.dart`
Expected: All 10 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/fetch_error.dart test/data/fetch_error_test.dart
git commit -m "Add FetchError enum for classifying network failures"
```

---

## Task 2: Classify errors in DataSource.fetchBytes

**Files:**
- Modify: `lib/data/data_source.dart:79-85`
- Modify: `test/data/data_source_test.dart`

- [ ] **Step 1: Write the failing test for classified fetch errors**

Add these tests to the existing `test/data/data_source_test.dart`:

```dart
// Add import at top:
import 'package:rpg_claude/data/fetch_error.dart';

// Add this group at end of main():
group('fetchBytes error classification', () {
  test('throws FetchException with serverError on HTTP 500', () async {
    // This test requires an HTTP mock — but DataSource.fetchBytes is static
    // and makes a real HTTP call. We test classification indirectly through
    // the loaders in Task 3. Here we verify the exception type exists.
    final ex = FetchException(FetchError.serverError);
    expect(ex.error, FetchError.serverError);
  });
});
```

Note: `DataSource.fetchBytes` makes real HTTP calls, so we can't unit-test HTTP status classification without adding an HTTP client parameter. The actual classification testing happens in Task 3 where loaders already accept a `fetchBytes` callback.

- [ ] **Step 2: Modify DataSource.fetchBytes to classify errors**

Replace `lib/data/data_source.dart:1-86` — the `fetchBytes` method (lines 79-85) needs to throw `FetchException` with the right type:

```dart
// In data_source.dart, add import at top:
import 'dart:async';
import 'dart:io';
import 'fetch_error.dart';

// Replace the fetchBytes method (lines 79-85):
  static Future<List<int>> fetchBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        throw FetchException(FetchError.fromStatusCode(response.statusCode));
      }
      return response.bodyBytes;
    } on FetchException {
      rethrow;
    } on TimeoutException {
      throw FetchException(FetchError.timeout);
    } on SocketException {
      throw FetchException(FetchError.noInternet);
    } on Exception {
      throw FetchException(FetchError.unknown);
    }
  }
```

- [ ] **Step 3: Run all tests to verify nothing breaks**

Run: `flutter test`
Expected: All existing tests PASS (the loaders catch all exceptions already, so `FetchException` is caught just like `Exception` was)

- [ ] **Step 4: Commit**

```bash
git add lib/data/data_source.dart test/data/data_source_test.dart
git commit -m "Classify fetch errors by type in DataSource.fetchBytes"
```

---

## Task 3: Propagate errors through DataLoader

**Files:**
- Modify: `lib/data/data_loader.dart:10-37`
- Modify: `test/data/data_loader_test.dart`

The loaders currently catch all exceptions and return `null`. We need them to still be resilient (skip individual failures), but when *all* fail, throw a `FetchException` with the most relevant error type rather than a generic `Exception`.

- [ ] **Step 1: Write the failing test for error propagation**

Add to `test/data/data_loader_test.dart`:

```dart
// Add import at top:
import 'dart:io';
import 'package:rpg_claude/data/fetch_error.dart';

// Add inside 'DataLoader.loadAll resilience' group:
test('throws FetchException with noInternet when all fail with SocketException', () async {
  final sources = [
    CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
    CsvSource(url: 'bad2', date: DateTime(2021, 1, 1)),
  ];

  expect(
    () => DataLoader.loadAll(
      sources: sources,
      fetchBytes: (url) async =>
          throw const SocketException('No route to host'),
    ),
    throwsA(
      isA<FetchException>().having(
        (e) => e.error,
        'error',
        FetchError.noInternet,
      ),
    ),
  );
});

test('throws FetchException with serverError on HTTP failures', () async {
  final sources = [
    CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
  ];

  expect(
    () => DataLoader.loadAll(
      sources: sources,
      fetchBytes: (url) async =>
          throw FetchException(FetchError.serverError),
    ),
    throwsA(
      isA<FetchException>().having(
        (e) => e.error,
        'error',
        FetchError.serverError,
      ),
    ),
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/data_loader_test.dart`
Expected: FAIL — throws generic `Exception('All CSV sources failed to load')` instead of `FetchException`

- [ ] **Step 3: Modify DataLoader to collect and propagate error types**

Replace `lib/data/data_loader.dart` with:

```dart
// ABOUTME: Orchestrates parallel fetching and parsing of all RPG CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'csv_parser.dart';
import 'data_source.dart';
import 'fetch_error.dart';
import 'models/record.dart';
import 'models/snapshot.dart';

class DataLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws FetchException with the most specific error when all sources fail.
  static Future<List<Snapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? DataSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final errors = <FetchError>[];
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return buildSnapshot(source.date, records);
      } on FetchException catch (e) {
        errors.add(e.error);
        return null;
      } on Exception catch (e) {
        errors.add(FetchError.classify(e));
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<Snapshot>().toList();
    if (snapshots.isEmpty) {
      throw FetchException(_pickMostRelevantError(errors));
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  static Snapshot buildSnapshot(DateTime date, List<Record> records) {
    return Snapshot(date: date, records: records);
  }

  static FetchError _pickMostRelevantError(List<FetchError> errors) {
    if (errors.isEmpty) return FetchError.unknown;
    // Priority: noInternet > timeout > serverError > clientError > unknown
    const priority = [
      FetchError.noInternet,
      FetchError.timeout,
      FetchError.serverError,
      FetchError.clientError,
      FetchError.unknown,
    ];
    for (final candidate in priority) {
      if (errors.contains(candidate)) return candidate;
    }
    return FetchError.unknown;
  }
}

// Top-level function required by compute().
List<Record> _parseInIsolate(List<int> bytes) {
  return CsvParser.parse(bytes);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/data_loader_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/data_loader.dart test/data/data_loader_test.dart
git commit -m "Propagate classified fetch errors through DataLoader"
```

---

## Task 4: Propagate errors through FarmSizeLoader and AgeLoader

**Files:**
- Modify: `lib/data/farm_size_loader.dart`
- Modify: `lib/data/age_loader.dart`
- Modify: `test/data/farm_size_loader_test.dart`
- Modify: `test/data/age_loader_test.dart`

Apply the same error propagation pattern from Task 3 to both secondary loaders.

- [ ] **Step 1: Write failing tests for FarmSizeLoader**

Add to `test/data/farm_size_loader_test.dart`:

```dart
// Add imports:
import 'dart:io';
import 'package:rpg_claude/data/fetch_error.dart';

// Add test:
test('throws FetchException with noInternet when all fail with SocketException', () async {
  final sources = [
    CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
  ];

  expect(
    () => FarmSizeLoader.loadAll(
      sources: sources,
      fetchBytes: (url) async =>
          throw const SocketException('No route to host'),
    ),
    throwsA(
      isA<FetchException>().having(
        (e) => e.error,
        'error',
        FetchError.noInternet,
      ),
    ),
  );
});
```

- [ ] **Step 2: Write failing tests for AgeLoader**

Add to `test/data/age_loader_test.dart`:

```dart
// Add imports:
import 'dart:io';
import 'package:rpg_claude/data/fetch_error.dart';

// Add test:
test('throws FetchException with noInternet when all fail with SocketException', () async {
  final sources = [
    CsvSource(url: 'bad1', date: DateTime(2020, 1, 1)),
  ];

  expect(
    () => AgeLoader.loadAll(
      sources: sources,
      fetchBytes: (url) async =>
          throw const SocketException('No route to host'),
    ),
    throwsA(
      isA<FetchException>().having(
        (e) => e.error,
        'error',
        FetchError.noInternet,
      ),
    ),
  );
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/data/farm_size_loader_test.dart test/data/age_loader_test.dart`
Expected: New tests FAIL

- [ ] **Step 4: Update FarmSizeLoader**

Replace `lib/data/farm_size_loader.dart` with the same pattern as DataLoader from Task 3 — add `FetchError` collection, `_pickMostRelevantError`, catch `FetchException` separately:

```dart
// ABOUTME: Orchestrates parallel fetching and parsing of all farm size CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'data_source.dart';
import 'farm_size_parser.dart';
import 'farm_size_source.dart';
import 'fetch_error.dart';
import 'models/farm_size_record.dart';
import 'models/farm_size_snapshot.dart';

class FarmSizeLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws FetchException with the most specific error when all sources fail.
  static Future<List<FarmSizeSnapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? FarmSizeSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final errors = <FetchError>[];
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return FarmSizeSnapshot(date: source.date, records: records);
      } on FetchException catch (e) {
        errors.add(e.error);
        return null;
      } on Exception catch (e) {
        errors.add(FetchError.classify(e));
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<FarmSizeSnapshot>().toList();
    if (snapshots.isEmpty) {
      throw FetchException(_pickMostRelevantError(errors));
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  static FetchError _pickMostRelevantError(List<FetchError> errors) {
    if (errors.isEmpty) return FetchError.unknown;
    const priority = [
      FetchError.noInternet,
      FetchError.timeout,
      FetchError.serverError,
      FetchError.clientError,
      FetchError.unknown,
    ];
    for (final candidate in priority) {
      if (errors.contains(candidate)) return candidate;
    }
    return FetchError.unknown;
  }
}

// Top-level function required by compute().
List<FarmSizeRecord> _parseInIsolate(List<int> bytes) {
  return FarmSizeParser.parse(bytes);
}
```

- [ ] **Step 5: Update AgeLoader**

Replace `lib/data/age_loader.dart` with the same pattern:

```dart
// ABOUTME: Orchestrates parallel fetching and parsing of all age structure CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'age_parser.dart';
import 'age_source.dart';
import 'data_source.dart';
import 'fetch_error.dart';
import 'models/age_record.dart';
import 'models/age_snapshot.dart';

class AgeLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first, skipping any sources that fail.
  // Throws FetchException with the most specific error when all sources fail.
  static Future<List<AgeSnapshot>> loadAll({
    List<CsvSource>? sources,
    Future<List<int>> Function(String url)? fetchBytes,
  }) async {
    final effectiveSources = sources ?? AgeSource.sources;
    final effectiveFetch = fetchBytes ?? DataSource.fetchBytes;
    final errors = <FetchError>[];
    final futures = effectiveSources.map((source) async {
      try {
        final bytes = await effectiveFetch(source.url);
        final records = await compute(_parseInIsolate, bytes);
        return AgeSnapshot(date: source.date, records: records);
      } on FetchException catch (e) {
        errors.add(e.error);
        return null;
      } on Exception catch (e) {
        errors.add(FetchError.classify(e));
        return null;
      }
    });
    final snapshots = (await Future.wait(
      futures,
    )).whereType<AgeSnapshot>().toList();
    if (snapshots.isEmpty) {
      throw FetchException(_pickMostRelevantError(errors));
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  static FetchError _pickMostRelevantError(List<FetchError> errors) {
    if (errors.isEmpty) return FetchError.unknown;
    const priority = [
      FetchError.noInternet,
      FetchError.timeout,
      FetchError.serverError,
      FetchError.clientError,
      FetchError.unknown,
    ];
    for (final candidate in priority) {
      if (errors.contains(candidate)) return candidate;
    }
    return FetchError.unknown;
  }
}

// Top-level function required by compute().
List<AgeRecord> _parseInIsolate(List<int> bytes) {
  return AgeParser.parse(bytes);
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/data/farm_size_loader_test.dart test/data/age_loader_test.dart`
Expected: All tests PASS

- [ ] **Step 7: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 8: Commit**

```bash
git add lib/data/farm_size_loader.dart lib/data/age_loader.dart test/data/farm_size_loader_test.dart test/data/age_loader_test.dart
git commit -m "Propagate classified fetch errors through FarmSizeLoader and AgeLoader"
```

---

## Task 5: Specific error messages on the Loading Screen

**Files:**
- Modify: `lib/screens/loading/loading_screen.dart`
- Modify: `test/screens/loading_screen_test.dart`

- [ ] **Step 1: Write failing tests for specific error messages**

Add to `test/screens/loading_screen_test.dart`:

```dart
// Add imports:
import 'package:rpg_claude/data/fetch_error.dart';

// Add tests:
testWidgets('shows no-internet message when FetchException is noInternet', (
  tester,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(
          () => _FetchErrorRepository(FetchError.noInternet),
        ),
      ],
      child: const MaterialApp(home: LoadingScreen()),
    ),
  );
  await tester.pump();
  expect(
    find.text(FetchError.noInternet.message),
    findsOneWidget,
  );
});

testWidgets('shows timeout message when FetchException is timeout', (
  tester,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(
          () => _FetchErrorRepository(FetchError.timeout),
        ),
      ],
      child: const MaterialApp(home: LoadingScreen()),
    ),
  );
  await tester.pump();
  expect(
    find.text(FetchError.timeout.message),
    findsOneWidget,
  );
});

testWidgets('shows server error message for serverError', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(
          () => _FetchErrorRepository(FetchError.serverError),
        ),
      ],
      child: const MaterialApp(home: LoadingScreen()),
    ),
  );
  await tester.pump();
  expect(
    find.text(FetchError.serverError.message),
    findsOneWidget,
  );
});

testWidgets('shows generic message for non-FetchException errors', (
  tester,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(() => _FailingRepository()),
      ],
      child: const MaterialApp(home: LoadingScreen()),
    ),
  );
  await tester.pump();
  expect(
    find.text(FetchError.unknown.message),
    findsOneWidget,
  );
});

// Add repository class:
class _FetchErrorRepository extends DataRepository {
  _FetchErrorRepository(this.errorType);
  final FetchError errorType;

  @override
  Future<List<Snapshot>> build() async =>
      throw FetchException(errorType);
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/screens/loading_screen_test.dart`
Expected: FAIL — loading screen shows generic "Greška pri učitavanju podataka" for all errors

- [ ] **Step 3: Update LoadingScreen to show specific messages**

Replace `lib/screens/loading/loading_screen.dart`:

```dart
// ABOUTME: Full-screen loading indicator shown while CSV data is being fetched.
// ABOUTME: Shows specific error messages based on failure type, with a retry button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fetch_error.dart';
import '../../providers/data_provider.dart';

class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return Scaffold(
      body: Center(
        child: dataAsync.when(
          loading: () => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Učitavanje podataka...'),
            ],
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dataRepositoryProvider),
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is FetchException) return error.error.message;
    return FetchError.unknown.message;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/screens/loading_screen_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Verify existing "shows error message and retry button on failure" test**

The existing test asserts `find.text('Greška pri učitavanju podataka')`. This will now fail since we changed the message. Update the assertion in that test:

```dart
// Change the existing test's assertion from:
expect(find.text('Greška pri učitavanju podataka'), findsOneWidget);
// to:
expect(find.text(FetchError.unknown.message), findsOneWidget);
```

- [ ] **Step 6: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add lib/screens/loading/loading_screen.dart test/screens/loading_screen_test.dart
git commit -m "Show specific error messages on loading screen based on failure type"
```

---

## Task 6: Pull-to-refresh on Pregled screen

**Files:**
- Modify: `lib/screens/pregled/pregled_screen.dart`
- Modify: `test/screens/pregled_screen_test.dart`

`RefreshIndicator` requires a `ScrollController` and only works with scrollable children. The Pregled screen already has a `SingleChildScrollView`, which is compatible.

- [ ] **Step 1: Write failing test for pull-to-refresh**

Add to `test/screens/pregled_screen_test.dart`:

```dart
// Add import:
import 'package:rpg_claude/data/fetch_error.dart';

testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();

  expect(find.byType(RefreshIndicator), findsOneWidget);
});

testWidgets('shows error message when farm size fails', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
        nameResolverProvider.overrideWith((ref) async => _resolver),
        farmSizeRepositoryProvider.overrideWith(
          () => _ErrorFarmSizeRepository(),
        ),
        ageRepositoryProvider.overrideWith(() => _FixtureAgeRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: PregledScreen())),
    ),
  );
  await tester.pumpAndSettle();

  // Should show error message instead of hiding the section
  expect(
    find.text('Podaci o veličini gazdinstava nisu dostupni'),
    findsOneWidget,
  );
});

testWidgets('shows error message when age data fails', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
        nameResolverProvider.overrideWith((ref) async => _resolver),
        farmSizeRepositoryProvider.overrideWith(
          () => _FixtureFarmSizeRepository(),
        ),
        ageRepositoryProvider.overrideWith(() => _ErrorAgeRepository()),
      ],
      child: const MaterialApp(home: Scaffold(body: PregledScreen())),
    ),
  );
  await tester.pumpAndSettle();

  // Should show error message instead of hiding the section
  expect(
    find.text('Podaci o starosnoj strukturi nisu dostupni'),
    findsOneWidget,
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/screens/pregled_screen_test.dart`
Expected: FAIL — no `RefreshIndicator`, error states still render `SizedBox.shrink()`

- [ ] **Step 3: Update PregledScreen — wrap with RefreshIndicator and add error states**

In `lib/screens/pregled/pregled_screen.dart`, make these changes:

**In `PregledScreen.build` (line 30-46):** Wrap the `SingleChildScrollView` with a `RefreshIndicator`. The `onRefresh` callback should invalidate only providers that are in error state. Since `PregledScreen` is a `ConsumerWidget`, we need to make the refresh callback available. Change `PregledScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` to hold the `ref`:

Actually, simpler approach — keep it as `ConsumerWidget` and pass `ref` into the body. The `RefreshIndicator` can go inside the `data:` callback:

Replace lines 33-45 (inside `data:` callback):

```dart
data: (snapshots) {
  if (snapshots.isEmpty) {
    return const Center(child: Text('Nema podataka'));
  }
  return ScreenScaffold(
    title: 'Pregled',
    child: RefreshIndicator(
      onRefresh: () async {
        final farmSizeState = ref.read(farmSizeRepositoryProvider);
        final ageState = ref.read(ageRepositoryProvider);
        if (farmSizeState.hasError) {
          ref.invalidate(farmSizeRepositoryProvider);
        }
        if (ageState.hasError) {
          ref.invalidate(ageRepositoryProvider);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: _PregledBody(snapshots: snapshots, resolver: resolver),
      ),
    ),
  );
},
```

Note the `AlwaysScrollableScrollPhysics()` — this ensures `RefreshIndicator` works even when content doesn't overflow.

**In `_FarmSizeSummary` (line 150):** Replace `error: (_, __) => const SizedBox.shrink()` with a visible error message:

```dart
error: (_, __) => _DataErrorMessage(
  message: 'Podaci o veličini gazdinstava nisu dostupni',
  onRetry: () => ref.invalidate(farmSizeRepositoryProvider),
),
```

**In `_AgeSummary` (line 278):** Replace `error: (_, __) => const SizedBox.shrink()` with:

```dart
error: (_, __) => _DataErrorMessage(
  message: 'Podaci o starosnoj strukturi nisu dostupni',
  onRetry: () => ref.invalidate(ageRepositoryProvider),
),
```

**Add the `_DataErrorMessage` widget at the bottom of the file** (before the closing of the file):

```dart
class _DataErrorMessage extends StatelessWidget {
  const _DataErrorMessage({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/screens/pregled_screen_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Update the existing "hides farm size section on error" and "hides age section on error" tests**

These tests currently assert that the section title is absent on error. Now it will be present (with an error message below). Update:

```dart
// In 'hides farm size section on error' — rename to 'shows error when farm size fails'
// Change from:
expect(find.text('Veličina gazdinstava'), findsNothing);
// to:
expect(find.text('Podaci o veličini gazdinstava nisu dostupni'), findsOneWidget);

// In 'hides age section on error' — rename to 'shows error when age data fails'
// Change from:
expect(find.text('Starosna struktura nosioca'), findsNothing);
// to:
expect(find.text('Podaci o starosnoj strukturi nisu dostupni'), findsOneWidget);
```

- [ ] **Step 6: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add lib/screens/pregled/pregled_screen.dart test/screens/pregled_screen_test.dart
git commit -m "Add pull-to-refresh and visible error states to Pregled screen"
```

---

## Task 7: Pull-to-refresh and error states on Opština Detail screen

**Files:**
- Modify: `lib/screens/opstine/opstina_detail_screen.dart`
- Modify: `test/screens/opstina_detail_screen_test.dart`

- [ ] **Step 1: Write failing tests**

Read `test/screens/opstina_detail_screen_test.dart` first to understand the fixture pattern, then add:

```dart
testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
  // Use existing _buildApp() or equivalent fixture setup
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();

  expect(find.byType(RefreshIndicator), findsOneWidget);
});

testWidgets('shows error message when farm size fails', (tester) async {
  // Build app with farm size provider overridden to fail
  await tester.pumpWidget(_buildAppWithFarmSizeError());
  await tester.pumpAndSettle();

  expect(
    find.text('Podaci o veličini gazdinstava nisu dostupni'),
    findsOneWidget,
  );
});

testWidgets('shows error message when age data fails', (tester) async {
  await tester.pumpWidget(_buildAppWithAgeError());
  await tester.pumpAndSettle();

  expect(
    find.text('Podaci o starosnoj strukturi nisu dostupni'),
    findsOneWidget,
  );
});
```

The exact fixture setup depends on what's already in the test file — read it and match the pattern.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/screens/opstina_detail_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Update OpstinaDetailScreen**

Apply the same pattern as Task 6:

1. Wrap `SingleChildScrollView` with `RefreshIndicator` + `AlwaysScrollableScrollPhysics()`
2. Replace `error: (_, __) => const SizedBox.shrink()` in `_FarmSizeDetail` (line 223) with visible error + retry
3. Replace `error: (_, __) => const SizedBox.shrink()` in `_AgeDetail` (line 328) with visible error + retry

The `_DataErrorMessage` widget is private to `pregled_screen.dart`. Since we need it here too, extract it to a shared location. Create it in `lib/widgets/data_error_message.dart`:

```dart
// lib/widgets/data_error_message.dart
// ABOUTME: Reusable widget showing a data unavailability message with optional retry.
// ABOUTME: Used across screens where secondary datasets may fail to load.

import 'package:flutter/material.dart';

class DataErrorMessage extends StatelessWidget {
  const DataErrorMessage({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

Then update `pregled_screen.dart` to import and use `DataErrorMessage` instead of the private `_DataErrorMessage`, and remove the private class. Update `opstina_detail_screen.dart` to import `DataErrorMessage` and use it in the error callbacks.

In `_FarmSizeDetail` (line 223), replace:
```dart
error: (_, __) => const SizedBox.shrink(),
```
with:
```dart
error: (_, __) => DataErrorMessage(
  message: 'Podaci o veličini gazdinstava nisu dostupni',
  onRetry: () => ref.invalidate(farmSizeRepositoryProvider),
),
```

In `_AgeDetail` (line 328), replace:
```dart
error: (_, __) => const SizedBox.shrink(),
```
with:
```dart
error: (_, __) => DataErrorMessage(
  message: 'Podaci o starosnoj strukturi nisu dostupni',
  onRetry: () => ref.invalidate(ageRepositoryProvider),
),
```

For RefreshIndicator on detail screen, wrap the `SingleChildScrollView` (around line 175) with:
```dart
RefreshIndicator(
  onRefresh: () async {
    final farmSizeState = ref.read(farmSizeRepositoryProvider);
    final ageState = ref.read(ageRepositoryProvider);
    if (farmSizeState.hasError) {
      ref.invalidate(farmSizeRepositoryProvider);
    }
    if (ageState.hasError) {
      ref.invalidate(ageRepositoryProvider);
    }
  },
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    ...
  ),
),
```

Note: `OpstinaDetailScreen` is a `ConsumerWidget`, so `ref` is available in `build()`. However, the `RefreshIndicator` needs `ref` in its callback. This works because `ref` is captured in the closure.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/screens/opstina_detail_screen_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/data_error_message.dart lib/screens/pregled/pregled_screen.dart lib/screens/opstine/opstina_detail_screen.dart test/screens/opstina_detail_screen_test.dart
git commit -m "Add pull-to-refresh and visible error states to Opština Detail screen"
```

---

## Task 8: Pull-to-refresh on Trendovi screen

**Files:**
- Modify: `lib/screens/trendovi/trendovi_screen.dart`
- Modify: `test/screens/trendovi_screen_test.dart`

Trendovi already shows error text inline (`Greška: $e`), but needs `RefreshIndicator` and the error text should use `DataErrorMessage` for consistency.

- [ ] **Step 1: Write failing test**

Add to `test/screens/trendovi_screen_test.dart`:

```dart
testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
  // Use existing fixture setup
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();

  expect(find.byType(RefreshIndicator), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/trendovi_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Update TrendoviScreen**

In `lib/screens/trendovi/trendovi_screen.dart`:

1. Import `DataErrorMessage`
2. Wrap `SingleChildScrollView` (line 98) with `RefreshIndicator` + `AlwaysScrollableScrollPhysics()`
3. Replace `SizedBox(height: 280, child: Center(child: Text('Greška: $e')))` in `_buildVelicinaChart` (line 214-215) with:
```dart
DataErrorMessage(
  message: 'Podaci o veličini gazdinstava nisu dostupni',
  onRetry: () => ref.invalidate(farmSizeRepositoryProvider),
),
```
4. Same for `_buildStarostChart` (line 246-247):
```dart
DataErrorMessage(
  message: 'Podaci o starosnoj strukturi nisu dostupni',
  onRetry: () => ref.invalidate(ageRepositoryProvider),
),
```
5. The `onRefresh` callback invalidates only error-state providers:
```dart
onRefresh: () async {
  if (_selectedDataset == _Dataset.velicina) {
    final state = ref.read(farmSizeRepositoryProvider);
    if (state.hasError) ref.invalidate(farmSizeRepositoryProvider);
  } else if (_selectedDataset == _Dataset.starost) {
    final state = ref.read(ageRepositoryProvider);
    if (state.hasError) ref.invalidate(ageRepositoryProvider);
  }
},
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/screens/trendovi_screen_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add lib/screens/trendovi/trendovi_screen.dart test/screens/trendovi_screen_test.dart
git commit -m "Add pull-to-refresh and consistent error states to Trendovi screen"
```

---

## Task 9: Responsive chart tooltip sizing

**Files:**
- Modify: `lib/utils/chart_helpers.dart`
- Create: `test/utils/tooltip_style_test.dart`
- Modify: `lib/screens/pregled/pregled_screen.dart`
- Modify: `lib/screens/opstine/opstina_detail_screen.dart`

- [ ] **Step 1: Write failing tests for tooltip style helper**

```dart
// test/utils/tooltip_style_test.dart
// ABOUTME: Tests for responsive tooltip sizing based on chart width and bar count.
// ABOUTME: Verifies font size scales down appropriately for smaller screens.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/utils/chart_helpers.dart';

void main() {
  group('tooltipFontSize', () {
    test('returns 11 for desktop-width chart with few bars', () {
      expect(tooltipFontSize(chartWidth: 800, barCount: 4), 11.0);
    });

    test('returns 9 for narrow chart with few bars', () {
      expect(tooltipFontSize(chartWidth: 350, barCount: 4), 9.0);
    });

    test('returns 7 for narrow chart with many bars', () {
      expect(tooltipFontSize(chartWidth: 350, barCount: 9), 7.0);
    });

    test('returns 9 for medium chart with many bars', () {
      expect(tooltipFontSize(chartWidth: 600, barCount: 9), 9.0);
    });

    test('never goes below 7', () {
      expect(tooltipFontSize(chartWidth: 200, barCount: 9), 7.0);
    });
  });

  group('showPermanentTooltips', () {
    test('true for desktop with few bars', () {
      expect(showPermanentTooltips(chartWidth: 800, barCount: 4), true);
    });

    test('true for mobile with few bars', () {
      expect(showPermanentTooltips(chartWidth: 350, barCount: 4), true);
    });

    test('false when bars too narrow for readable labels', () {
      expect(showPermanentTooltips(chartWidth: 250, barCount: 9), false);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/utils/tooltip_style_test.dart`
Expected: FAIL — functions don't exist

- [ ] **Step 3: Add tooltip helpers to chart_helpers.dart**

Add to `lib/utils/chart_helpers.dart`:

```dart
/// Calculates tooltip font size based on available chart width and bar count.
/// Scales down for narrower charts with more bars to prevent overlap.
double tooltipFontSize({required double chartWidth, required int barCount}) {
  final barWidth = barCount > 0 ? chartWidth / barCount : chartWidth;
  if (barWidth >= 80) return 11.0;
  if (barWidth >= 50) return 9.0;
  return 7.0;
}

/// Whether to show permanent tooltip labels above bars.
/// Returns false when bars are too narrow for readable labels — in that case
/// the chart should use tap-to-show tooltips instead.
bool showPermanentTooltips({required double chartWidth, required int barCount}) {
  final barWidth = barCount > 0 ? chartWidth / barCount : chartWidth;
  return barWidth >= 30;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/utils/tooltip_style_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/utils/chart_helpers.dart test/utils/tooltip_style_test.dart
git commit -m "Add responsive tooltip sizing helpers to chart_helpers"
```

---

## Task 10: Apply responsive tooltips to Pregled screen charts

**Files:**
- Modify: `lib/screens/pregled/pregled_screen.dart`

The Pregled screen has two bar charts that show permanent tooltips: the org form chart (`_BarChartSection`, 7 bars) and the age bracket chart (`_AgeSummary`, 9 bars). Both need `LayoutBuilder` to get the chart width and use the new helpers.

- [ ] **Step 1: Update `_BarChartSection` to use responsive tooltips**

Wrap the `SizedBox` (line 453-507) in a `LayoutBuilder` and use the width:

Replace the `SizedBox(height: ...)` block in `_BarChartSection.build`:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final chartWidth = constraints.maxWidth;
    final barCount = OrgForm.values.length;
    final permanent = showPermanentTooltips(
      chartWidth: chartWidth,
      barCount: barCount,
    );
    final fontSize = tooltipFontSize(
      chartWidth: chartWidth,
      barCount: barCount,
    );

    return SizedBox(
      height: isDesktop(context) ? 360 : 240,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.15,
          barGroups: OrgForm.values.asMap().entries.map((entry) {
            final value = byOrgForm[entry.value] ?? 0;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: value.toDouble(),
                  width: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
              showingTooltipIndicators:
                  permanent && value > 0 ? [0] : [],
            );
          }).toList(),
          barTouchData: BarTouchData(
            enabled: !permanent,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  const Color.fromARGB(255, 237, 191, 136),
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final fmt = NumberFormat('#,###', 'sr');
                return BarTooltipItem(
                  fmt.format(rod.toY.toInt()),
                  TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final form = OrgForm.values[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      form.displayName.split(' ').first,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  },
),
```

Note: When `permanent` is false (too narrow), `enabled: true` on `BarTouchData` means users can tap a bar to see its tooltip. `showingTooltipIndicators` is empty so no permanent labels.

- [ ] **Step 2: Update `_AgeSummary` to use responsive tooltips**

Same pattern — wrap the `SizedBox(height: ...)` at line 327-404 in a `LayoutBuilder`:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final chartWidth = constraints.maxWidth;
    final barCount = sortedBrackets.length;
    final permanent = showPermanentTooltips(
      chartWidth: chartWidth,
      barCount: barCount,
    );
    final fontSize = tooltipFontSize(
      chartWidth: chartWidth,
      barCount: barCount,
    );

    return SizedBox(
      height: isDesktop(context) ? 280 : 200,
      child: BarChart(
        BarChartData(
          maxY: maxCount * 1.15,
          barGroups: sortedBrackets
              .asMap()
              .entries
              .map(
                (entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      width: 16,
                      color: primary,
                    ),
                  ],
                  showingTooltipIndicators:
                      permanent && entry.value.value > 0
                          ? [0]
                          : [],
                ),
              )
              .toList(),
          barTouchData: BarTouchData(
            enabled: !permanent,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  const Color.fromARGB(255, 237, 191, 136),
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItem:
                  (group, groupIndex, rod, rodIndex) {
                    final fmt = NumberFormat('#,###', 'sr');
                    return BarTooltipItem(
                      fmt.format(rod.toY.toInt()),
                      TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize,
                      ),
                    );
                  },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sortedBrackets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sortedBrackets[idx].key.displayName,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  },
),
```

- [ ] **Step 3: Add import for the new helpers**

Add to the imports in `pregled_screen.dart`:

```dart
import '../../utils/chart_helpers.dart';
```

- [ ] **Step 4: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/pregled/pregled_screen.dart
git commit -m "Apply responsive tooltip sizing to Pregled screen bar charts"
```

---

## Task 11: Apply responsive tooltips to Opština Detail bar charts

**Files:**
- Modify: `lib/screens/opstine/opstina_detail_screen.dart`

The detail screen has two bar charts (`_FarmSizeDetail` with 4 bars and `_AgeDetail` with up to 9 bars) that currently have NO tooltip configuration at all. Add tooltips with responsive sizing.

- [ ] **Step 1: Update `_FarmSizeDetail` bar chart (line 250-302)**

Wrap the `SizedBox(height: 180, ...)` in a `LayoutBuilder` and add tooltip config:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final chartWidth = constraints.maxWidth;
    final barCount = brackets.length;
    final permanent = showPermanentTooltips(
      chartWidth: chartWidth,
      barCount: barCount,
    );
    final fontSize = tooltipFontSize(
      chartWidth: chartWidth,
      barCount: barCount,
    );

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (var i = 0; i < brackets.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: brackets[i].$2.toDouble(),
                    color: Theme.of(context).colorScheme.primary,
                    width: 22,
                  ),
                ],
                showingTooltipIndicators:
                    permanent && brackets[i].$2 > 0 ? [0] : [],
              ),
          ],
          barTouchData: BarTouchData(
            enabled: !permanent,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  const Color.fromARGB(255, 237, 191, 136),
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toInt().toString(),
                  TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= brackets.length) {
                    return const SizedBox();
                  }
                  return Text(
                    brackets[idx].$1,
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  abbreviateCount(value),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  },
),
```

- [ ] **Step 2: Update `_AgeDetail` bar chart (line 356-407)**

Same pattern:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final chartWidth = constraints.maxWidth;
    final barCount = sorted.length;
    final permanent = showPermanentTooltips(
      chartWidth: chartWidth,
      barCount: barCount,
    );
    final fontSize = tooltipFontSize(
      chartWidth: chartWidth,
      barCount: barCount,
    );

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (var i = 0; i < sorted.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: sorted[i].value.toDouble(),
                    color: Theme.of(context).colorScheme.primary,
                    width: 22,
                  ),
                ],
                showingTooltipIndicators:
                    permanent && sorted[i].value > 0 ? [0] : [],
              ),
          ],
          barTouchData: BarTouchData(
            enabled: !permanent,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  const Color.fromARGB(255, 237, 191, 136),
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toInt().toString(),
                  TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox();
                  }
                  return Text(
                    sorted[idx].key.displayName,
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  abbreviateCount(value),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  },
),
```

- [ ] **Step 3: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add lib/screens/opstine/opstina_detail_screen.dart
git commit -m "Apply responsive tooltip sizing to Opština Detail bar charts"
```

---

## Task 12: Empty state for Mapa overlays (improve existing)

**Files:**
- Modify: `lib/screens/mapa/mapa_screen.dart`

The Mapa screen already has some error/empty handling in its overlays, but the error messages are generic. Update them to be more specific and consistent.

- [ ] **Step 1: Update error messages in `_FarmSizeOverlay`**

In `lib/screens/mapa/mapa_screen.dart`, line 730-736, replace:
```dart
Text(
  'Greška pri učitavanju podataka',
  style: Theme.of(context).textTheme.bodySmall,
),
```
with:
```dart
Text(
  'Podaci o veličini gazdinstava nisu dostupni',
  style: Theme.of(context).textTheme.bodySmall,
),
```

- [ ] **Step 2: Update error messages in `_AgeOverlay`**

Line 886-893, replace:
```dart
Text(
  'Greška pri učitavanju podataka',
  style: Theme.of(context).textTheme.bodySmall,
),
```
with:
```dart
Text(
  'Podaci o starosnoj strukturi nisu dostupni',
  style: Theme.of(context).textTheme.bodySmall,
),
```

- [ ] **Step 3: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add lib/screens/mapa/mapa_screen.dart
git commit -m "Use specific error messages in Mapa overlay panels"
```

---

## Task 13: Final verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: Verify ABOUTME comments on all new/modified files**

Check that every file created or modified has the two-line ABOUTME comment at the top. Files to verify:
- `lib/data/fetch_error.dart`
- `lib/widgets/data_error_message.dart`
- `test/data/fetch_error_test.dart`
- `test/utils/tooltip_style_test.dart`

- [ ] **Step 4: Commit any remaining fixes**

If any issues were found and fixed:
```bash
git add -A
git commit -m "Fix issues found during final verification"
```
