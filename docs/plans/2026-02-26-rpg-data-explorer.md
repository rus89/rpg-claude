# RPG Data Explorer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Flutter mobile + web app that fetches, parses, and visualises Serbia's registered agricultural holdings open data across 5 screens.

**Architecture:** Pure Flutter client — no backend. On cold start, all 12 CSV files are fetched in parallel from data.gov.rs, parsed in a compute isolate, and held in a Riverpod `DataRepository` provider. All screens derive their data from filtered/aggregated projections of that in-memory store.

**Tech Stack:** `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`, `go_router`, `http`, `csv`, `fl_chart`, `flutter_map` + `latlong2`, `build_runner`

> **CORS note:** On web, browser CORS policy applies to HTTP fetches. Test Task 4's fetcher on web early. If data.gov.rs blocks CORS, raise with Milan before continuing — do not work around it silently.

> **Encoding note:** CSVs use `;` as delimiter. Encoding is likely Windows-1250 or UTF-8 — test in Task 3 and handle accordingly.

> **Code rules:** All file headers MUST start with two `// ABOUTME:` lines. All identifiers/comments in English. All UI strings in Serbian Latin.

---

## File Structure

```
lib/
  main.dart
  app.dart
  data/
    models/
      org_form.dart
      record.dart
      snapshot.dart
    csv_parser.dart
    data_source.dart
    data_loader.dart
  providers/
    data_provider.dart          ← DataRepository (AsyncNotifier)
    loading_provider.dart       ← LoadingState
  screens/
    loading/loading_screen.dart
    pregled/pregled_screen.dart
    opstine/
      opstine_screen.dart
      opstina_detail_screen.dart
    trendovi/trendovi_screen.dart
    mapa/mapa_screen.dart
    o_aplikaciji/o_aplikaciji_screen.dart
  navigation/
    router.dart
    shell.dart
assets/
  geojson/
    serbia_municipalities.geojson   ← obtain from GADM level-2 (see Task 12)
test/
  data/
    csv_parser_test.dart
    data_source_test.dart
  providers/
    data_provider_test.dart
  screens/
    loading_screen_test.dart
    pregled_screen_test.dart
    opstine_screen_test.dart
    trendovi_screen_test.dart
    mapa_screen_test.dart
integration_test/
  app_test.dart
```

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Update pubspec.yaml dependencies**

Replace the `dependencies` and `dev_dependencies` sections with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.6.1
  http: ^1.2.2
  csv: ^6.0.0
  fl_chart: ^0.70.2
  flutter_map: ^7.0.2
  latlong2: ^0.9.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.6.1
  build_runner: ^2.4.13
  riverpod_lint: ^2.6.1
  custom_lint: ^0.7.3
```

> Check pub.dev for the latest compatible versions before running pub get.

**Step 2: Fetch dependencies**

```bash
flutter pub get
```

Expected: resolves without conflicts.

**Step 3: Verify analyze still passes**

```bash
flutter analyze
```

Expected: No issues found.

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "Add project dependencies"
```

---

## Task 2: Data Models

**Files:**
- Create: `lib/data/models/org_form.dart`
- Create: `lib/data/models/record.dart`
- Create: `lib/data/models/snapshot.dart`
- Test: `test/data/models_test.dart`

**Step 1: Write the failing test**

Create `test/data/models_test.dart`:

```dart
// ABOUTME: Tests for core data model types.
// ABOUTME: Covers OrgForm, Record, and Snapshot construction and equality.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';

void main() {
  group('OrgForm', () {
    test('fromCode returns correct enum value', () {
      expect(OrgForm.fromCode(1), OrgForm.familyFarm);
      expect(OrgForm.fromCode(7), OrgForm.religiousOrganization);
    });

    test('fromCode throws for unknown code', () {
      expect(() => OrgForm.fromCode(99), throwsArgumentError);
    });
  });

  group('Record', () {
    test('constructs with all fields', () {
      final record = Record(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 1417,
        activeHoldings: 1385,
      );
      expect(record.municipalityName, 'Barajevo');
      expect(record.activeHoldings, 1385);
    });
  });

  group('Snapshot', () {
    test('constructs with date and records', () {
      final snapshot = Snapshot(
        date: DateTime(2025, 12, 31),
        records: [],
      );
      expect(snapshot.date.year, 2025);
      expect(snapshot.records, isEmpty);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/data/models_test.dart
```

Expected: FAIL — files don't exist yet.

**Step 3: Create `lib/data/models/org_form.dart`**

```dart
// ABOUTME: Enum representing the organizational form of an agricultural holding.
// ABOUTME: Maps the integer codes from the RPG CSV data to named values.

enum OrgForm {
  familyFarm,
  company,
  entrepreneur,
  agriculturalCooperative,
  legalEntityFarm,
  researchOrganization,
  religiousOrganization;

  static OrgForm fromCode(int code) {
    return switch (code) {
      1 => OrgForm.familyFarm,
      2 => OrgForm.company,
      3 => OrgForm.entrepreneur,
      4 => OrgForm.agriculturalCooperative,
      5 => OrgForm.legalEntityFarm,
      6 => OrgForm.researchOrganization,
      7 => OrgForm.religiousOrganization,
      _ => throw ArgumentError('Unknown org form code: $code'),
    };
  }

  String get displayName => switch (this) {
        OrgForm.familyFarm => 'Porodično gazdinstvo',
        OrgForm.company => 'Preduzeće',
        OrgForm.entrepreneur => 'Preduzetnik',
        OrgForm.agriculturalCooperative => 'Zemljoradnička zadruga',
        OrgForm.legalEntityFarm => 'Gazdinstvo - pravno lice',
        OrgForm.researchOrganization => 'Naučno-istraživačka organizacija',
        OrgForm.religiousOrganization => 'Verska organizacija',
      };
}
```

**Step 4: Create `lib/data/models/record.dart`**

```dart
// ABOUTME: Immutable data model for a single row in the RPG CSV dataset.
// ABOUTME: Represents one municipality × organizational form combination at a point in time.

import 'org_form.dart';

class Record {
  const Record({
    required this.regionCode,
    required this.regionName,
    required this.municipalityCode,
    required this.municipalityName,
    required this.orgForm,
    required this.totalRegistered,
    required this.activeHoldings,
  });

  final String regionCode;
  final String regionName;
  final String municipalityCode;
  final String municipalityName;
  final OrgForm orgForm;
  final int totalRegistered;
  final int activeHoldings;
}
```

**Step 5: Create `lib/data/models/snapshot.dart`**

```dart
// ABOUTME: Immutable container for all records from one RPG CSV snapshot file.
// ABOUTME: Each snapshot corresponds to a single point-in-time data release.

import 'record.dart';

class Snapshot {
  const Snapshot({
    required this.date,
    required this.records,
  });

  final DateTime date;
  final List<Record> records;
}
```

**Step 6: Run tests to verify they pass**

```bash
flutter test test/data/models_test.dart
```

Expected: All tests PASS.

**Step 7: Commit**

```bash
git add lib/data/models/ test/data/models_test.dart
git commit -m "Add OrgForm, Record, and Snapshot data models"
```

---

## Task 3: CSV Parser

**Files:**
- Create: `lib/data/csv_parser.dart`
- Test: `test/data/csv_parser_test.dart`

The CSV uses `;` as a field separator. Encoding is likely UTF-8 or Windows-1250 — the parser receives raw bytes and tries UTF-8 first, then falls back to Latin-1.

**Step 1: Write the failing test**

Create `test/data/csv_parser_test.dart`:

```dart
// ABOUTME: Tests for CSV parsing logic.
// ABOUTME: Covers delimiter handling, encoding fallback, and malformed row skipping.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/csv_parser.dart';
import 'package:rpg_claude/data/models/org_form.dart';

void main() {
  group('CsvParser.parse', () {
    test('parses valid semicolon-delimited CSV bytes into records', () {
      const content = 'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;1417;1385\n'
          '1;GRAD BEOGRAD;10;Barajevo;2;Preduzeca;8;8\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 2);
      expect(records[0].municipalityName, 'Barajevo');
      expect(records[0].orgForm, OrgForm.familyFarm);
      expect(records[0].totalRegistered, 1417);
      expect(records[0].activeHoldings, 1385);
    });

    test('skips rows with non-integer count fields', () {
      const content = 'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;1;Porodicno;bad;1385\n'
          '1;GRAD BEOGRAD;10;Barajevo;2;Preduzeca;8;8\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 1);
    });

    test('skips rows with unknown org form code', () {
      const content = 'Regija;NazivRegije;SifraOpstine;NazivOpstineL;OrgOblik;NazivOrgOblik;broj gazdinstava;AktivnaGazdinstva\n'
          '1;GRAD BEOGRAD;10;Barajevo;99;Unknown;10;10\n';
      final bytes = utf8.encode(content);
      final records = CsvParser.parse(bytes);
      expect(records.length, 0);
    });

    test('returns empty list for empty file', () {
      final bytes = utf8.encode('');
      final records = CsvParser.parse(bytes);
      expect(records, isEmpty);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/data/csv_parser_test.dart
```

Expected: FAIL — `CsvParser` does not exist.

**Step 3: Create `lib/data/csv_parser.dart`**

```dart
// ABOUTME: Parses raw bytes from an RPG CSV snapshot file into a list of Records.
// ABOUTME: Handles semicolon delimiter and UTF-8/Latin-1 encoding fallback.

import 'dart:convert';
import 'package:csv/csv.dart';
import 'models/org_form.dart';
import 'models/record.dart';

class CsvParser {
  // Returns an empty list if the bytes are empty or unparseable.
  static List<Record> parse(List<int> bytes) {
    if (bytes.isEmpty) return [];

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final rows = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.length < 2) return [];

    // Skip header row (index 0)
    final records = <Record>[];
    for (final row in rows.skip(1)) {
      if (row.length < 8) continue;
      try {
        final orgFormCode = int.parse(row[4].toString().trim());
        final totalRegistered = int.parse(row[6].toString().trim());
        final activeHoldings = int.parse(row[7].toString().trim());
        records.add(Record(
          regionCode: row[0].toString().trim(),
          regionName: row[1].toString().trim(),
          municipalityCode: row[2].toString().trim(),
          municipalityName: row[3].toString().trim(),
          orgForm: OrgForm.fromCode(orgFormCode),
          totalRegistered: totalRegistered,
          activeHoldings: activeHoldings,
        ));
      } catch (_) {
        // Skip malformed rows silently
        continue;
      }
    }
    return records;
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/data/csv_parser_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/data/csv_parser.dart test/data/csv_parser_test.dart
git commit -m "Add CSV parser with semicolon delimiter and encoding fallback"
```

---

## Task 4: Data Source

**Files:**
- Create: `lib/data/data_source.dart`
- Test: `test/data/data_source_test.dart`

This class holds the hardcoded list of 12 CSV URLs with their snapshot dates, and exposes a method to fetch the raw bytes of a single URL.

**Step 1: Write the failing test**

Create `test/data/data_source_test.dart`:

```dart
// ABOUTME: Tests for DataSource — verifies the URL list is complete and fetch contracts.
// ABOUTME: Does not make real HTTP calls; only tests the source list shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/data_source.dart';

void main() {
  group('DataSource', () {
    test('provides exactly 12 CSV sources', () {
      expect(DataSource.sources.length, 12);
    });

    test('all sources have non-empty URLs and valid dates', () {
      for (final source in DataSource.sources) {
        expect(source.url, isNotEmpty);
        expect(source.date.year, greaterThanOrEqualTo(2018));
      }
    });

    test('sources are ordered oldest to newest', () {
      final dates = DataSource.sources.map((s) => s.date).toList();
      for (int i = 1; i < dates.length; i++) {
        expect(dates[i].isAfter(dates[i - 1]), isTrue,
            reason: 'Source $i is not after source ${i - 1}');
      }
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/data/data_source_test.dart
```

Expected: FAIL — `DataSource` does not exist.

**Step 3: Create `lib/data/data_source.dart`**

```dart
// ABOUTME: Hardcoded list of all RPG CSV snapshot URLs with their data dates.
// ABOUTME: Exposes a fetch method that returns raw bytes for a given URL.

import 'package:http/http.dart' as http;

class CsvSource {
  const CsvSource({required this.url, required this.date});
  final String url;
  final DateTime date;
}

class DataSource {
  static const List<CsvSource> sources = [
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20180226-130228/Srbija_broj_gazinstava_po_opstinama_prema_organizacionom_obliku.csv',
      date: DateTime(2018, 2, 26),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20180528-090355/Srbija_broj_gazinstava_po_opstinama_prema_organizacionom_obliku_05_28.csv',
      date: DateTime(2018, 5, 28),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20180815-081910/Srbija_broj-gazinstava_po_opstinama_organizacionom_obliku_08_15.csv',
      date: DateTime(2018, 8, 15),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20190717-093917/srbija-broj-gazinstava-po-opstinama-organizacionom-obliku-07-17-2019.csv',
      date: DateTime(2019, 7, 17),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20200615-130128/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-06-15-2020.csv',
      date: DateTime(2020, 6, 15),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20210610-095742/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-06-10-2021.csv',
      date: DateTime(2021, 6, 10),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20211201-134751/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-01-12-2021.csv',
      date: DateTime(2021, 12, 1),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20220928-111852/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-28-09-2022.csv',
      date: DateTime(2022, 9, 28),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20241025-085857/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-25-10-2024.csv',
      date: DateTime(2024, 10, 25),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20250121-104213/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-31-12-2024.csv',
      date: DateTime(2024, 12, 31),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20250707-085335/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-07-07-2025.csv',
      date: DateTime(2025, 7, 7),
    ),
    CsvSource(
      url: 'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20260108-073108/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-31-12-2025.csv',
      date: DateTime(2025, 12, 31),
    ),
  ];

  // Fetches raw bytes for a single CSV URL.
  // Throws HttpException on non-200 responses.
  static Future<List<int>> fetchBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch $url: HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/data/data_source_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/data/data_source.dart test/data/data_source_test.dart
git commit -m "Add DataSource with hardcoded CSV URLs and fetch method"
```

---

## Task 5: Data Loader

**Files:**
- Create: `lib/data/data_loader.dart`
- Test: `test/data/data_loader_test.dart`

Fetches all 12 CSVs in parallel using `Future.wait`, parses each in a `compute` isolate, and returns `List<Snapshot>`.

**Step 1: Write the failing test**

Create `test/data/data_loader_test.dart`:

```dart
// ABOUTME: Tests for DataLoader snapshot assembly logic.
// ABOUTME: Verifies that snapshots are built correctly from parsed records.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/data_loader.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';

void main() {
  group('DataLoader.buildSnapshot', () {
    test('combines date and records into a Snapshot', () {
      final date = DateTime(2025, 12, 31);
      final records = [
        Record(
          regionCode: '1',
          regionName: 'GRAD BEOGRAD',
          municipalityCode: '10',
          municipalityName: 'Barajevo',
          orgForm: OrgForm.familyFarm,
          totalRegistered: 100,
          activeHoldings: 90,
        ),
      ];
      final snapshot = DataLoader.buildSnapshot(date, records);
      expect(snapshot.date, date);
      expect(snapshot.records.length, 1);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/data/data_loader_test.dart
```

Expected: FAIL — `DataLoader` does not exist.

**Step 3: Create `lib/data/data_loader.dart`**

```dart
// ABOUTME: Orchestrates parallel fetching and parsing of all RPG CSV snapshots.
// ABOUTME: Uses compute isolates for parsing to avoid blocking the UI thread.

import 'package:flutter/foundation.dart';
import 'csv_parser.dart';
import 'data_source.dart';
import 'models/record.dart';
import 'models/snapshot.dart';

class DataLoader {
  // Fetches and parses all CSV sources in parallel.
  // Returns snapshots sorted oldest-first.
  static Future<List<Snapshot>> loadAll() async {
    final futures = DataSource.sources.map((source) async {
      final bytes = await DataSource.fetchBytes(source.url);
      final records = await compute(_parseInIsolate, bytes);
      return buildSnapshot(source.date, records);
    });
    final snapshots = await Future.wait(futures);
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return snapshots;
  }

  static Snapshot buildSnapshot(DateTime date, List<Record> records) {
    return Snapshot(date: date, records: records);
  }
}

// Top-level function required by compute().
List<Record> _parseInIsolate(List<int> bytes) {
  return CsvParser.parse(bytes);
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/data/data_loader_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/data/data_loader.dart test/data/data_loader_test.dart
git commit -m "Add DataLoader for parallel CSV fetch and isolate parsing"
```

---

## Task 6: Riverpod Providers

**Files:**
- Create: `lib/providers/data_provider.dart`
- Test: `test/providers/data_provider_test.dart`

A single `AsyncNotifier` holds `List<Snapshot>`. A separate derived provider exposes the sorted list of unique municipality names. Both are accessed by screens via Riverpod's `ref.watch`.

**Step 1: Write the failing test**

Create `test/providers/data_provider_test.dart`:

```dart
// ABOUTME: Tests for the DataRepository Riverpod provider.
// ABOUTME: Uses a ProviderContainer with overridden data to avoid HTTP calls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';

final _testSnapshots = [
  Snapshot(
    date: DateTime(2025, 12, 31),
    records: [
      Record(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '10',
        municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 100,
        activeHoldings: 90,
      ),
      Record(
        regionCode: '1',
        regionName: 'GRAD BEOGRAD',
        municipalityCode: '11',
        municipalityName: 'Čukarica',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 200,
        activeHoldings: 180,
      ),
    ],
  ),
];

void main() {
  group('municipalityNamesProvider', () {
    test('returns sorted unique municipality names from snapshots', () async {
      final container = ProviderContainer(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FakeDataRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Wait for async provider to complete
      await container.read(dataRepositoryProvider.future);

      final names = container.read(municipalityNamesProvider);
      expect(names, ['Barajevo', 'Čukarica']);
    });
  });
}

class _FakeDataRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _testSnapshots;
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/providers/data_provider_test.dart
```

Expected: FAIL — providers don't exist yet.

**Step 3: Create `lib/providers/data_provider.dart`**

```dart
// ABOUTME: Riverpod providers for the loaded RPG dataset.
// ABOUTME: DataRepository is the root async provider; derived providers expose filtered views.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/data_loader.dart';
import '../data/models/snapshot.dart';

part 'data_provider.g.dart';

@riverpod
class DataRepository extends _$DataRepository {
  @override
  Future<List<Snapshot>> build() => DataLoader.loadAll();
}

// Returns all unique municipality names sorted alphabetically.
@riverpod
List<String> municipalityNames(Ref ref) {
  final snapshots = ref.watch(dataRepositoryProvider).valueOrNull ?? [];
  final names = snapshots
      .expand((s) => s.records)
      .map((r) => r.municipalityName)
      .toSet()
      .toList()
    ..sort();
  return names;
}
```

**Step 4: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/providers/data_provider.g.dart`.

**Step 5: Run tests to verify they pass**

```bash
flutter test test/providers/data_provider_test.dart
```

Expected: All tests PASS.

**Step 6: Commit**

```bash
git add lib/providers/ test/providers/
git commit -m "Add DataRepository and municipalityNames Riverpod providers"
```

---

## Task 7: App Skeleton and Navigation

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/app.dart`
- Create: `lib/navigation/router.dart`
- Create: `lib/navigation/shell.dart`
- Create: `lib/screens/loading/loading_screen.dart` (placeholder)
- Create: `lib/screens/pregled/pregled_screen.dart` (placeholder)
- Create: `lib/screens/opstine/opstine_screen.dart` (placeholder)
- Create: `lib/screens/trendovi/trendovi_screen.dart` (placeholder)
- Create: `lib/screens/mapa/mapa_screen.dart` (placeholder)
- Create: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart` (placeholder)

**Step 1: Update `lib/main.dart`**

```dart
// ABOUTME: App entry point — initialises Riverpod and launches the app.
// ABOUTME: ProviderScope wraps the entire widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}
```

**Step 2: Create `lib/app.dart`**

```dart
// ABOUTME: Root widget — configures MaterialApp with GoRouter and Serbian locale.
// ABOUTME: Watches the data loading state to decide which initial route to show.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'RPG Srbija',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
    );
  }
}
```

**Step 3: Create `lib/navigation/router.dart`**

```dart
// ABOUTME: GoRouter configuration with 5 main tab routes.
// ABOUTME: Redirects to loading screen until data is available.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/pregled/pregled_screen.dart';
import '../screens/opstine/opstine_screen.dart';
import '../screens/trendovi/trendovi_screen.dart';
import '../screens/mapa/mapa_screen.dart';
import '../screens/o_aplikaciji/o_aplikaciji_screen.dart';
import '../providers/data_provider.dart';
import 'shell.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final dataAsync = ref.watch(dataRepositoryProvider);

  return GoRouter(
    initialLocation: '/ucitavanje',
    redirect: (context, state) {
      final isLoading = dataAsync.isLoading;
      final isOnLoading = state.matchedLocation == '/ucitavanje';
      if (isLoading && !isOnLoading) return '/ucitavanje';
      if (!isLoading && isOnLoading) return '/pregled';
      return null;
    },
    routes: [
      GoRoute(
        path: '/ucitavanje',
        builder: (context, state) => const LoadingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/pregled',
            builder: (context, state) => const PregledScreen(),
          ),
          GoRoute(
            path: '/opstine',
            builder: (context, state) => const OpstineScreen(),
          ),
          GoRoute(
            path: '/trendovi',
            builder: (context, state) => const TrendoviScreen(),
          ),
          GoRoute(
            path: '/mapa',
            builder: (context, state) => const MapaScreen(),
          ),
          GoRoute(
            path: '/o-aplikaciji',
            builder: (context, state) => const OAplikacijiScreen(),
          ),
        ],
      ),
    ],
  );
}
```

**Step 4: Create `lib/navigation/shell.dart`**

```dart
// ABOUTME: Bottom navigation shell widget — wraps all main tab screens.
// ABOUTME: Highlights the active tab and handles tab switching via GoRouter.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_pathFor(index)),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Pregled'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Opštine'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Trendovi'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'O aplikaciji'),
        ],
      ),
    );
  }

  int _indexFor(String location) => switch (location) {
        '/pregled' => 0,
        '/opstine' => 1,
        '/trendovi' => 2,
        '/mapa' => 3,
        '/o-aplikaciji' => 4,
        _ => 0,
      };

  String _pathFor(int index) => switch (index) {
        0 => '/pregled',
        1 => '/opstine',
        2 => '/trendovi',
        3 => '/mapa',
        4 => '/o-aplikaciji',
        _ => '/pregled',
      };
}
```

**Step 5: Create placeholder screens**

Each placeholder follows this pattern (shown for Pregled; repeat for the other four):

```dart
// ABOUTME: Pregled (overview) screen — shows national agricultural holdings summary.
// ABOUTME: Placeholder until Task 9 is implemented.

import 'package:flutter/material.dart';

class PregledScreen extends StatelessWidget {
  const PregledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Pregled')));
  }
}
```

Create all six:
- `lib/screens/loading/loading_screen.dart` — class `LoadingScreen`
- `lib/screens/pregled/pregled_screen.dart` — class `PregledScreen`
- `lib/screens/opstine/opstine_screen.dart` — class `OpstineScreen`
- `lib/screens/trendovi/trendovi_screen.dart` — class `TrendoviScreen`
- `lib/screens/mapa/mapa_screen.dart` — class `MapaScreen`
- `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart` — class `OAplikacijiScreen`

**Step 6: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 7: Verify app builds and runs**

```bash
flutter analyze
flutter test
```

Expected: No issues, existing tests pass.

**Step 8: Commit**

```bash
git add lib/main.dart lib/app.dart lib/navigation/ lib/screens/
git commit -m "Add app skeleton with GoRouter navigation and placeholder screens"
```

---

## Task 8: Loading Screen

**Files:**
- Modify: `lib/screens/loading/loading_screen.dart`
- Test: `test/screens/loading_screen_test.dart`

Shows a progress indicator while data loads. On error, shows the error message and a retry button.

**Step 1: Write the failing test**

Create `test/screens/loading_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the loading screen.
// ABOUTME: Covers loading, error, and retry states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/loading/loading_screen.dart';

void main() {
  testWidgets('shows progress indicator while loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _NeverCompleteRepository(),
          ),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message and retry button on failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _FailingRepository(),
          ),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Greška pri učitavanju podataka'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
  });
}

class _NeverCompleteRepository extends DataRepository {
  @override
  Future<List<dynamic>> build() => Completer<List<dynamic>>().future;
}

class _FailingRepository extends DataRepository {
  @override
  Future<List<dynamic>> build() async => throw Exception('Network error');
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/loading_screen_test.dart
```

Expected: FAIL — `LoadingScreen` is a placeholder.

**Step 3: Implement `lib/screens/loading/loading_screen.dart`**

```dart
// ABOUTME: Full-screen loading indicator shown while CSV data is being fetched.
// ABOUTME: Shows error message and retry button if the fetch fails.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Greška pri učitavanju podataka'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(dataRepositoryProvider),
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

```bash
flutter test test/screens/loading_screen_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/screens/loading/ test/screens/loading_screen_test.dart
git commit -m "Implement loading screen with error and retry states"
```

---

## Task 9: Pregled Screen

**Files:**
- Modify: `lib/screens/pregled/pregled_screen.dart`
- Test: `test/screens/pregled_screen_test.dart`

Shows national totals for the most recent snapshot: a summary card (total registered, total active) and a bar chart showing active holdings by org form.

**Step 1: Write the failing test**

Create `test/screens/pregled_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the Pregled (overview) screen.
// ABOUTME: Verifies national totals and bar chart render with fixture data.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/pregled/pregled_screen.dart';

final _fixtureSnapshots = [
  Snapshot(
    date: DateTime(2025, 12, 31),
    records: [
      Record(
        regionCode: '1', regionName: 'R1',
        municipalityCode: '10', municipalityName: 'Barajevo',
        orgForm: OrgForm.familyFarm,
        totalRegistered: 1000, activeHoldings: 900,
      ),
      Record(
        regionCode: '1', regionName: 'R1',
        municipalityCode: '10', municipalityName: 'Barajevo',
        orgForm: OrgForm.company,
        totalRegistered: 50, activeHoldings: 40,
      ),
    ],
  ),
];

void main() {
  testWidgets('shows total registered and active holdings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _FixtureRepository(),
          ),
        ],
        child: const MaterialApp(home: PregledScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('1.050'), findsOneWidget); // total registered
    expect(find.text('940'), findsOneWidget);   // total active
  });

  testWidgets('renders a bar chart', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
        ],
        child: const MaterialApp(home: PregledScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(BarChart), findsOneWidget);
  });
}

class _FixtureRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtureSnapshots;
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/pregled_screen_test.dart
```

Expected: FAIL.

**Step 3: Implement `lib/screens/pregled/pregled_screen.dart`**

```dart
// ABOUTME: Pregled (overview) screen showing national RPG totals for the latest snapshot.
// ABOUTME: Displays summary cards and a bar chart broken down by organizational form.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/org_form.dart';
import '../../providers/data_provider.dart';

class PregledScreen extends ConsumerWidget {
  const PregledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return dataAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return const Scaffold(body: Center(child: Text('Nema podataka')));
        }
        final latest = snapshots.last;
        final totalRegistered = latest.records.fold(0, (sum, r) => sum + r.totalRegistered);
        final totalActive = latest.records.fold(0, (sum, r) => sum + r.activeHoldings);
        final fmt = NumberFormat('#,###', 'sr');

        final byOrgForm = <OrgForm, int>{};
        for (final r in latest.records) {
          byOrgForm[r.orgForm] = (byOrgForm[r.orgForm] ?? 0) + r.activeHoldings;
        }

        final barGroups = OrgForm.values.asMap().entries.map((entry) {
          final value = byOrgForm[entry.value] ?? 0;
          return BarChartGroupData(x: entry.key, barRods: [
            BarChartRodData(toY: value.toDouble(), width: 16,
                color: Theme.of(context).colorScheme.primary),
          ]);
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Pregled')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Podaci na dan: ${DateFormat('dd.MM.yyyy').format(latest.date)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _SummaryCard(
                      label: 'Ukupno registrovanih', value: fmt.format(totalRegistered))),
                    const SizedBox(width: 12),
                    Expanded(child: _SummaryCard(
                      label: 'Aktivnih gazdinstava', value: fmt.format(totalActive))),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Aktivna gazdinstva po obliku organizacije',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
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
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
```

> Note: `intl` package is needed for `NumberFormat`. Add `intl: ^0.20.0` to `pubspec.yaml` and run `flutter pub get`.

**Step 4: Run tests**

```bash
flutter test test/screens/pregled_screen_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/screens/pregled/ test/screens/pregled_screen_test.dart pubspec.yaml pubspec.lock
git commit -m "Implement Pregled screen with summary cards and bar chart"
```

---

## Task 10: Opštine Screen

**Files:**
- Modify: `lib/screens/opstine/opstine_screen.dart`
- Create: `lib/screens/opstine/opstina_detail_screen.dart`
- Test: `test/screens/opstine_screen_test.dart`

A searchable list of municipalities. Tapping opens a detail screen with the current breakdown by org form and a mini trend line.

**Step 1: Write the failing test**

Create `test/screens/opstine_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the Opštine (municipalities) screen.
// ABOUTME: Covers list rendering, search filtering, and navigation to detail.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/opstine/opstine_screen.dart';

final _fixtureSnapshots = [
  Snapshot(
    date: DateTime(2025, 12, 31),
    records: [
      Record(regionCode: '1', regionName: 'R1',
          municipalityCode: '10', municipalityName: 'Barajevo',
          orgForm: OrgForm.familyFarm, totalRegistered: 100, activeHoldings: 90),
      Record(regionCode: '1', regionName: 'R1',
          municipalityCode: '11', municipalityName: 'Čukarica',
          orgForm: OrgForm.familyFarm, totalRegistered: 200, activeHoldings: 180),
    ],
  ),
];

void main() {
  testWidgets('shows all municipality names', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
      child: const MaterialApp(home: OpstineScreen()),
    ));
    await tester.pump();
    expect(find.text('Barajevo'), findsOneWidget);
    expect(find.text('Čukarica'), findsOneWidget);
  });

  testWidgets('search filters the list', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
      child: const MaterialApp(home: OpstineScreen()),
    ));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bara');
    await tester.pump();
    expect(find.text('Barajevo'), findsOneWidget);
    expect(find.text('Čukarica'), findsNothing);
  });
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtureSnapshots;
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/opstine_screen_test.dart
```

Expected: FAIL.

**Step 3: Implement `lib/screens/opstine/opstine_screen.dart`**

```dart
// ABOUTME: Opštine screen — searchable list of all municipalities in the dataset.
// ABOUTME: Tapping a municipality navigates to its detail screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_provider.dart';

class OpstineScreen extends ConsumerStatefulWidget {
  const OpstineScreen({super.key});

  @override
  ConsumerState<OpstineScreen> createState() => _OpstineScreenState();
}

class _OpstineScreenState extends ConsumerState<OpstineScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allNames = ref.watch(municipalityNamesProvider);
    final filtered = allNames
        .where((n) => n.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Opštine')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pretraži opštine...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final name = filtered[index];
                return ListTile(
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/opstine/$name'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Create `lib/screens/opstine/opstina_detail_screen.dart`**

```dart
// ABOUTME: Detail screen for a single municipality — shows active holdings by org form.
// ABOUTME: Includes a mini trend line showing active holdings across all snapshots.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/org_form.dart';
import '../../providers/data_provider.dart';

class OpstinaDetailScreen extends ConsumerWidget {
  const OpstinaDetailScreen({super.key, required this.municipalityName});
  final String municipalityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return dataAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final fmt = NumberFormat('#,###', 'sr');
        final latest = snapshots.last;
        final latestRecords = latest.records
            .where((r) => r.municipalityName == municipalityName)
            .toList();

        // Trend: total active per snapshot
        final trendSpots = snapshots.asMap().entries.map((entry) {
          final total = entry.value.records
              .where((r) => r.municipalityName == municipalityName)
              .fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(entry.key.toDouble(), total.toDouble());
        }).toList();

        return Scaffold(
          appBar: AppBar(title: Text(municipalityName)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aktivna gazdinstva po obliku',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...latestRecords.map((r) => ListTile(
                      title: Text(r.orgForm.displayName),
                      trailing: Text(fmt.format(r.activeHoldings)),
                    )),
                const SizedBox(height: 24),
                const Text('Trend aktivnih gazdinstava',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(spots: trendSpots, isCurved: true),
                    ],
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

**Step 5: Add the detail route to `lib/navigation/router.dart`**

Inside the `ShellRoute.routes` list, add:

```dart
GoRoute(
  path: '/opstine/:name',
  builder: (context, state) => OpstinaDetailScreen(
    municipalityName: state.pathParameters['name']!,
  ),
),
```

**Step 6: Run tests**

```bash
flutter test test/screens/opstine_screen_test.dart
```

Expected: All tests PASS.

**Step 7: Commit**

```bash
git add lib/screens/opstine/ lib/navigation/router.dart test/screens/opstine_screen_test.dart
git commit -m "Implement Opštine screen with search and municipality detail"
```

---

## Task 11: Trendovi Screen

**Files:**
- Modify: `lib/screens/trendovi/trendovi_screen.dart`
- Test: `test/screens/trendovi_screen_test.dart`

Line chart with all 12 snapshots on the X-axis. Filters for municipality and org form. Supports multiple series.

**Step 1: Write the failing test**

Create `test/screens/trendovi_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the Trendovi (trends) screen.
// ABOUTME: Verifies the line chart renders and filters respond to selection.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/trendovi/trendovi_screen.dart';

final _fixtures = [
  Snapshot(date: DateTime(2024, 1, 1), records: [
    Record(regionCode: '1', regionName: 'R', municipalityCode: '10',
        municipalityName: 'Barajevo', orgForm: OrgForm.familyFarm,
        totalRegistered: 100, activeHoldings: 90),
  ]),
  Snapshot(date: DateTime(2025, 1, 1), records: [
    Record(regionCode: '1', regionName: 'R', municipalityCode: '10',
        municipalityName: 'Barajevo', orgForm: OrgForm.familyFarm,
        totalRegistered: 110, activeHoldings: 100),
  ]),
];

void main() {
  testWidgets('renders a line chart', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
      child: const MaterialApp(home: TrendoviScreen()),
    ));
    await tester.pump();
    expect(find.byType(LineChart), findsOneWidget);
  });
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => _fixtures;
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/trendovi_screen_test.dart
```

Expected: FAIL.

**Step 3: Implement `lib/screens/trendovi/trendovi_screen.dart`**

```dart
// ABOUTME: Trendovi screen — shows active holdings over time as a line chart.
// ABOUTME: Supports filtering by municipality and organizational form.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/org_form.dart';
import '../../providers/data_provider.dart';

class TrendoviScreen extends ConsumerStatefulWidget {
  const TrendoviScreen({super.key});

  @override
  ConsumerState<TrendoviScreen> createState() => _TrendoviScreenState();
}

class _TrendoviScreenState extends ConsumerState<TrendoviScreen> {
  String? _selectedMunicipality; // null = national total
  Set<OrgForm> _selectedForms = OrgForm.values.toSet();

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final allNames = ref.watch(municipalityNamesProvider);

    return dataAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final spots = snapshots.asMap().entries.map((entry) {
          final records = entry.value.records.where((r) {
            final matchesMunicipality = _selectedMunicipality == null ||
                r.municipalityName == _selectedMunicipality;
            final matchesForm = _selectedForms.contains(r.orgForm);
            return matchesMunicipality && matchesForm;
          });
          final total = records.fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(entry.key.toDouble(), total.toDouble());
        }).toList();

        final xLabels = snapshots.map((s) => DateFormat('MM/yy').format(s.date)).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Trendovi')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Municipality selector
                DropdownButtonFormField<String?>(
                  value: _selectedMunicipality,
                  decoration: const InputDecoration(
                    labelText: 'Opština',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Srbija (ukupno)')),
                    ...allNames.map((n) => DropdownMenuItem(value: n, child: Text(n))),
                  ],
                  onChanged: (v) => setState(() => _selectedMunicipality = v),
                ),
                const SizedBox(height: 12),
                // Org form chips
                Wrap(
                  spacing: 8,
                  children: OrgForm.values.map((form) => FilterChip(
                    label: Text(form.displayName),
                    selected: _selectedForms.contains(form),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _selectedForms.add(form)
                          : _selectedForms.remove(form);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 280,
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= xLabels.length) return const SizedBox();
                            return Text(xLabels[idx],
                                style: const TextStyle(fontSize: 9));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                  )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/screens/trendovi_screen_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/screens/trendovi/ test/screens/trendovi_screen_test.dart
git commit -m "Implement Trendovi screen with line chart and filters"
```

---

## Task 12: Mapa Screen

**Files:**
- Modify: `lib/screens/mapa/mapa_screen.dart`
- Add asset: `assets/geojson/serbia_municipalities.geojson`
- Modify: `pubspec.yaml` (declare asset)
- Test: `test/screens/mapa_screen_test.dart`

**Step 1: Obtain Serbia municipality GeoJSON**

Download level-2 administrative boundaries for Serbia from GADM:
`https://gadm.org/download_country.html` → country: Serbia → GeoJSON → Level 2

Save to `assets/geojson/serbia_municipalities.geojson`.

The `NAME_2` property in GADM GeoJSON contains municipality names. These must be matched against `municipalityName` in our records. **There will likely be spelling mismatches** (e.g. diacritics, spelling differences). Write a normalisation helper (strip diacritics, lowercase, trim) to fuzzy-match them. Handle unmatched municipalities gracefully (render in grey).

**Step 2: Declare asset in `pubspec.yaml`**

```yaml
flutter:
  assets:
    - assets/geojson/serbia_municipalities.geojson
```

**Step 3: Write the failing test**

Create `test/screens/mapa_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the Mapa (map) screen.
// ABOUTME: Verifies the FlutterMap widget renders with fixture data.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/mapa/mapa_screen.dart';

void main() {
  testWidgets('renders FlutterMap widget', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWith(() => _Fixture()),
      ],
      child: const MaterialApp(home: MapaScreen()),
    ));
    await tester.pump();
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [
        Snapshot(
          date: DateTime(2025, 12, 31),
          records: [
            Record(
              regionCode: '1', regionName: 'R',
              municipalityCode: '10', municipalityName: 'Barajevo',
              orgForm: OrgForm.familyFarm,
              totalRegistered: 100, activeHoldings: 90,
            ),
          ],
        ),
      ];
}
```

**Step 4: Run test to verify it fails**

```bash
flutter test test/screens/mapa_screen_test.dart
```

Expected: FAIL.

**Step 5: Implement `lib/screens/mapa/mapa_screen.dart`**

```dart
// ABOUTME: Mapa screen — choropleth map of Serbia coloured by active holdings per municipality.
// ABOUTME: Uses bundled GeoJSON and flutter_map; tapping a municipality shows an info card.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/org_form.dart';
import '../../providers/data_provider.dart';

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  Map<String, dynamic>? _geoJson;
  String? _tappedMunicipality;
  OrgForm? _selectedOrgForm; // null = all forms combined

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    final raw = await rootBundle.loadString('assets/geojson/serbia_municipalities.geojson');
    if (mounted) setState(() => _geoJson = jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return dataAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        if (_geoJson == null || snapshots.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final latest = snapshots.last;
        final activeByMunicipality = <String, int>{};
        for (final r in latest.records) {
          if (_selectedOrgForm != null && r.orgForm != _selectedOrgForm) continue;
          final key = _normalise(r.municipalityName);
          activeByMunicipality[key] = (activeByMunicipality[key] ?? 0) + r.activeHoldings;
        }

        final maxValue = activeByMunicipality.values.fold(0, (a, b) => a > b ? a : b);

        return Scaffold(
          appBar: AppBar(title: const Text('Mapa')),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(44.0, 21.0),
                  initialZoom: 7.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.serbiaOpenData.rpg',
                  ),
                  // GeoJSON polygon layer rendered manually via PolygonLayer
                  // TODO(map): render choropleth polygons from _geoJson
                  // See flutter_map docs for GeoJSON polygon rendering pattern.
                ],
              ),
              if (_tappedMunicipality != null)
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_tappedMunicipality!,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${activeByMunicipality[_normalise(_tappedMunicipality!)] ?? 0} aktivnih'),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _tappedMunicipality = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Strips diacritics and lowercases for fuzzy name matching.
  String _normalise(String name) {
    return name
        .toLowerCase()
        .replaceAll('š', 's').replaceAll('đ', 'dj').replaceAll('č', 'c')
        .replaceAll('ć', 'c').replaceAll('ž', 'z')
        .trim();
  }
}
```

> **Note on choropleth rendering:** The TODO above marks where GeoJSON polygon rendering goes. This requires iterating `_geoJson['features']`, converting each geometry to `flutter_map` `Polygon` objects, and colouring them based on `activeByMunicipality`. Implement this as a follow-up once the GeoJSON asset is obtained and name matching is validated. The map still renders the tile layer and info card without this.

**Step 6: Run tests**

```bash
flutter test test/screens/mapa_screen_test.dart
```

Expected: All tests PASS.

**Step 7: Commit**

```bash
git add lib/screens/mapa/ assets/ pubspec.yaml test/screens/mapa_screen_test.dart
git commit -m "Implement Mapa screen with flutter_map tile layer and info card"
```

---

## Task 13: O aplikaciji Screen

**Files:**
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- Test: `test/screens/o_aplikaciji_screen_test.dart`

Static content screen with disclaimer, data source link, and per-tab guide.

**Step 1: Write the failing test**

Create `test/screens/o_aplikaciji_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the O aplikaciji (about) screen.
// ABOUTME: Verifies disclaimer text and data source credit are present.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/screens/o_aplikaciji/o_aplikaciji_screen.dart';

void main() {
  testWidgets('shows disclaimer text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.textContaining('nezavisan'), findsWidgets);
  });

  testWidgets('shows data source credit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.textContaining('data.gov.rs'), findsOneWidget);
  });

  testWidgets('shows guide for all 4 main tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    await tester.scrollUntilVisible(find.text('Pregled'), 100);
    expect(find.text('Pregled'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Opštine'), 100);
    expect(find.text('Opštine'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: FAIL.

**Step 3: Implement `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`**

```dart
// ABOUTME: O aplikaciji screen — static content with disclaimer and per-screen guide.
// ABOUTME: Explains data source and independence from government bodies.

import 'package:flutter/material.dart';

class OAplikacijiScreen extends StatelessWidget {
  const OAplikacijiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O aplikaciji')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'O aplikaciji',
              body: 'Ova aplikacija prikazuje otvorene podatke o registrovanim '
                  'poljoprivrednim gazdinstvima u Srbiji (RPG), preuzete sa portala '
                  'data.gov.rs. Cilj aplikacije je obrazovni — da omogući svim '
                  'zainteresovanim građanima lak pristup ovim podacima.',
            ),
            const Divider(height: 32),
            _Section(
              title: 'Napomena o nezavisnosti',
              body: 'Ova aplikacija je razvio nezavisan developer i nije '
                  'povezana ni sa jednim državnim organom, institucijom ili '
                  'organizacijom. Podaci se preuzimaju direktno sa portala '
                  'data.gov.rs i koriste se isključivo u informativne i '
                  'obrazovne svrhe.',
            ),
            const Divider(height: 32),
            _Section(
              title: 'Izvor podataka',
              body: 'Podaci potiču od Uprave za agrarna plaćanja i dostupni '
                  'su na: data.gov.rs',
            ),
            const Divider(height: 32),
            const Text('Vodič kroz aplikaciju',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const _TabGuide(
              tabName: 'Pregled',
              description: 'Prikazuje ukupan broj registrovanih i aktivnih gazdinstava '
                  'na nivou Srbije za najnoviji dostupni snimak podataka, kao i '
                  'raspodelu po obliku organizacije.',
            ),
            const _TabGuide(
              tabName: 'Opštine',
              description: 'Pretraži sve opštine i pogledaj detalje za svaku — '
                  'aktivan broj gazdinstava po obliku organizacije i trend kroz vreme.',
            ),
            const _TabGuide(
              tabName: 'Trendovi',
              description: 'Prati kako se broj aktivnih gazdinstava menjao od 2018. '
                  'do danas. Filtriraj po opštini i obliku organizacije, ili '
                  'poređaj više opština na istom grafikonu.',
            ),
            const _TabGuide(
              tabName: 'Mapa',
              description: 'Geografski prikaz Srbije — opštine su obojene prema broju '
                  'aktivnih gazdinstava. Dodirnite opštinu za kratki pregled.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(body),
      ],
    );
  }
}

class _TabGuide extends StatelessWidget {
  const _TabGuide({required this.tabName, required this.description});
  final String tabName;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tabName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}
```

**Step 4: Run tests**

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/screens/o_aplikaciji/ test/screens/o_aplikaciji_screen_test.dart
git commit -m "Implement O aplikaciji screen with disclaimer and tab guide"
```

---

## Task 14: Integration Test

**Files:**
- Create: `integration_test/app_test.dart`

Runs the full app against real data. No mocks. Asserts Pregled shows non-zero totals.

**Step 1: Write the test**

Create `integration_test/app_test.dart`:

```dart
// ABOUTME: End-to-end integration test — launches full app and verifies live data loads.
// ABOUTME: Makes real HTTP requests to data.gov.rs; no mocks.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpg_claude/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads data and shows non-zero totals on Pregled', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // After data loads, loading screen should be gone
    expect(find.text('Učitavanje podataka...'), findsNothing);

    // At least one number appears on screen (national total)
    expect(find.textContaining(RegExp(r'\d{3,}')), findsWidgets);
  });
}
```

**Step 2: Run integration test on a connected device or emulator**

```bash
flutter test integration_test/app_test.dart
```

Expected: PASS — app loads, Pregled shows data.

> If CORS blocks web fetches, this test will fail on the web target. Raise with Milan if that happens — do not work around it silently.

**Step 3: Commit**

```bash
git add integration_test/
git commit -m "Add end-to-end integration test for live data loading"
```

---

## Final Checklist

Before declaring the implementation complete:

- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all unit + widget tests pass, output is pristine
- [ ] Integration test passes on at least one real platform (iOS or Android)
- [ ] Web tested manually — verify CORS is not blocking fetches
- [ ] All files start with two `// ABOUTME:` lines
- [ ] All UI strings are in Serbian Latin
- [ ] All identifiers and comments are in English
