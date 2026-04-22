# RPG Data Explorer — Design Document

**Date:** 2026-02-26
**Status:** Approved
**Data source:** https://data.gov.rs/sr/datasets/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/

---

## Overview

A Flutter mobile and web app that presents open data from Serbia's Registered Agricultural Holdings (RPG) registry to the Serbian public. The app fetches data directly from data.gov.rs and provides a full-featured explorer: trends over time, municipality-level detail, organizational form breakdown, and a choropleth map.

**Language:** UI in Serbian Latin; codebase (variables, functions, comments, file names) in English.
**Target platforms:** Mobile (iOS + Android) and Web.

---

## Section 1 — Architecture

The app is a pure Flutter client — no backend, no database. On cold start, all 12 CSV files are fetched from data.gov.rs in parallel, parsed in a compute isolate, and loaded into memory. A full-screen loading indicator shows progress during this phase. Once loaded, all navigation and filtering is instant.

**State management:** Riverpod. A single `DataRepository` provider owns the raw parsed data. Derived providers (filtered by municipality, organizational form, time range) sit on top of it and are composed as needed by each screen.

**Navigation:** GoRouter with a bottom navigation bar containing five tabs:
1. **Pregled** — national overview
2. **Opštine** — municipality browser
3. **Trendovi** — time-series charts
4. **Mapa** — choropleth map
5. **O aplikaciji** — about / disclaimer

---

## Section 2 — Data Model

Each CSV file is a snapshot at a point in time. The raw CSV columns are:

| Column | Description |
|---|---|
| `Regija` | Region code |
| `NazivRegije` | Region name |
| `SifraOpstine` | Municipality code |
| `NazivOpstineL` | Municipality name (Latin) |
| `OrgOblik` | Organizational form code |
| `NazivOrgOblik` | Organizational form name |
| `broj gazdinstava` | Total registered holdings |
| `AktivnaGazdinstva` | Active holdings |

**Dart types:**

```dart
// One point-in-time snapshot (one CSV file)
class Snapshot {
  final DateTime date;
  final List<Record> records;
}

// One row in a snapshot
class Record {
  final String regionCode;
  final String regionName;
  final String municipalityCode;
  final String municipalityName;
  final String orgFormCode;
  final String orgFormName;
  final int totalRegistered;
  final int activeHoldings;
}
```

All 12 snapshots are held in a `List<Snapshot>` by `DataRepository`. Region is stored in the model but **not** exposed as a UI filter (YAGNI). Organizational form codes are normalized to a known enum during parsing so filters are type-safe.

---

## Section 3 — Screens

### Pregled (Overview)
Landing screen. Shows national totals for the most recent snapshot: total registered holdings, total active holdings, and a bar chart breakdown by organizational form. Displays the snapshot date as a "last updated" label.

### Opštine (Municipalities)
Searchable, scrollable list of all municipalities. Tapping one opens a detail screen with: current total and active counts broken down by org form, plus a mini trend line showing active holdings across all 12 snapshots.

### Trendovi (Trends)
Line chart with all 12 snapshots on the X-axis. Defaults to national totals. Users can filter by municipality (search/select) and by organizational form. Multiple series can be shown simultaneously for side-by-side comparison.

### Mapa (Map)
Choropleth map of Serbia colored by active holdings count in the most recent snapshot. Municipality GeoJSON bundled as an asset. Tapping a municipality shows a small info card. Organizational form filter applies here too.

### O aplikaciji (About)
Static content:
- What the app is and its educational purpose
- **Disclaimer:** independent developer, no affiliation with the government or any public body
- Data source credit with a link to data.gov.rs
- Brief guide to what each tab offers

---

## Section 4 — Technical Stack

| Concern | Library |
|---|---|
| State management | `flutter_riverpod` + `riverpod_annotation` |
| Navigation | `go_router` |
| HTTP fetching | `http` |
| CSV parsing | `csv` |
| Charts | `fl_chart` |
| Map | `flutter_map` + `latlong2` |
| Immutable models | `freezed` + `json_serializable` |

**Data loading flow:**
1. App starts → loading screen shown
2. `DataLoader` provider fetches all 12 CSV URLs via `Future.wait` (parallel)
3. Each CSV is parsed in a `compute` isolate
4. Results merged into `List<Snapshot>` and stored in `DataRepository`
5. App navigates to Pregled

If any fetch fails, a clear error message is shown with a retry button (best-effort, no offline cache in v1).

**Filtering:**
A global `FilterState` (selected municipality, selected org forms, selected time range) lives in a Riverpod `StateNotifier`. All chart and table providers watch it and recompute automatically.

---

## Section 5 — Testing Strategy

All features follow TDD: failing test first, then implementation.

**Unit tests**
- CSV parser: correct column mapping, malformed row handling, aggregation correctness
- `FilterState` and all derived Riverpod providers, tested with hand-crafted fixture data

**Widget tests**
- Each screen tested with a `ProviderScope` override (no real HTTP calls)
- Verify correct data renders given fixture data; verify filter changes cause expected UI updates

**Integration tests**
- One end-to-end smoke test: full app launch, real CSV fetch from data.gov.rs, assert Pregled shows non-zero national totals
- No mocks in integration tests — real data, real APIs

No golden tests in v1.
