# RPG Srbija App Improvements — Implementation Plan

## Context

The app has 6 interconnected issues: a too-simple Pregled screen, unreadable bar chart tooltips, broken Opštine navigation for diacritics names, misleading Trendovi/detail charts, grey Mapa polygons, and a missing link on the About page. Investigation revealed a **root cause**: the CSV parser uses hardcoded column indices while the government CSV files have inconsistent column names and ordering across snapshots. This silently produces wrong data, cascading into chart anomalies, zero-count municipalities, and grey map polygons.

## Design Decisions (approved by Milan)

- **CSV parser**: Rewrite to use header-based column mapping with known name variants
- **Name reconstruction**: Use GeoJSON names as authoritative display source; aggregated CSV entries (e.g., "Majdanpek/D.Milan44290") kept as combined list entries, excluded from map
- **Pregled additions**: Delta indicators on summary cards, activity rate card, values above bars, top 5 by active count, top 5 by growth rate, bottom 5 declining
- **Chart fixes**: `isCurved: false`, proportional date-based x-axis, y-axis labels
- **Mapa**: Grey polygons show explanatory note on tap; fixed upstream by parser + name resolution
- **O aplikaciji**: Tappable link to specific RPG dataset page (requires `url_launcher` dependency — approved)

## Implementation Sequence

### Phase 1: Data Foundation (sequential, blocking)

#### Task 1: CSV Parser Rewrite

**Files:**
- Modify: `lib/data/csv_parser.dart` — rewrite `parse()` to read header row, build column-position map
- Modify: `test/data/csv_parser_test.dart` — add tests for variant headers, missing columns, column reordering
- Modify: `test/data/data_loader_test.dart` — update `_csvContent` fixture (currently uses fake headers like `sifra_regiona` that won't match any variant)

**Column name variant mapping (case-insensitive, trimmed):**

| Canonical | Variants |
|---|---|
| regionCode | "Regija", "SifRegije" |
| regionName | "NazivRegije" |
| municipalityCode | "SifraOpstine" |
| municipalityName | "NazivOpstineL" |
| orgFormCode | "OrgOblik" |
| orgFormName | "NazivOrgOblik" (not used in model) |
| totalRegistered | "broj gazdinstava", "BrojGazdinstavaSva", "Broj Gazdinstava" |
| activeHoldings | "AktivnaGazdinstva", "BrojGazdinstavaAktivna", "Broj aktivnih gazdinstava", "broj Aktivna gazdinstva" |

**Rules:**
- Required columns: regionCode, municipalityName, orgFormCode, totalRegistered — if any missing, return `[]`
- If activeHoldings missing: default to 0 per row (handles Oct 2024 CSV)
- Header matching: lowercase + trim before comparing

**New tests needed:**
- Parses CSV with alternative header names (e.g., `SifRegije;NazivRegije;...;BrojGazdinstavaAktivna`)
- Parses CSV without activeHoldings column, defaults to 0
- Returns empty list when required column missing
- Header matching is case-insensitive
- Columns in any order still parse correctly

#### Task 2: NameResolver + Navigation Fix

**Files:**
- Create: `lib/data/name_resolver.dart` — maps corrupted CSV names → correct GeoJSON names via normalisation
- Create: `test/data/name_resolver_test.dart`
- Modify: `lib/screens/opstine/opstine_screen.dart:49` — URL-encode name before `context.push()`
- Modify: `lib/navigation/router.dart` — URL-decode `state.pathParameters['name']`
- Modify: `lib/providers/data_provider.dart` — add `nameResolverProvider` that loads GeoJSON names and creates resolver

**NameResolver design:**
- Constructor takes list of GeoJSON municipality names (from `NAME_2` properties in bundled GeoJSON)
- Builds `Map<String, String>` from `normaliseSerbianName(geoJsonName) → geoJsonName`
- `resolve(csvName)` → returns GeoJSON name or `null` for unmatched (aggregated entries)
- `displayName(csvName)` → resolved name with CamelCase splitting, or cleaned-up raw name for aggregated entries
- Reuses existing `normaliseSerbianName()` from `lib/data/serbian_normalise.dart`

**Navigation fix:**
- `context.push('/opstine/${Uri.encodeComponent(name)}')` in opstine_screen.dart
- `Uri.decodeComponent(state.pathParameters['name']!)` in router.dart

---

### Phase 2: Screen Improvements (parallelisable after Phase 1)

#### Task 3: Pregled Screen Enhancements

**Files:**
- Modify: `lib/screens/pregled/pregled_screen.dart` — major additions
- Modify: `test/screens/pregled_screen_test.dart` — expand fixtures (need 2+ snapshots, 5+ municipalities)

**Sub-tasks in order:**

**3a. Delta indicators on summary cards**
- Compare latest vs previous snapshot totals
- Show "+X.Y%" / "-X.Y%" with arrow icon beneath the big number
- Defensive guard: if only 1 snapshot loaded, hide delta

**3b. Activity rate card**
- Third summary card: `active / registered × 100` as "XX.Y%"
- Label: "Stopa aktivnosti"

**3c. Bar chart: permanent value labels**
- Show formatted count above each bar permanently
- Remove tooltip-on-tap (default fl_chart behavior)
- Use `showingTooltipIndicators` on all bar groups to display values

**3d. Top 5 municipalities by active count**
- Aggregate activeHoldings by municipality from latest snapshot
- Sort descending, take 5
- Tappable rows → navigate to detail (URL-encoded)
- Use resolved display names from NameResolver

**3e. Top 5 municipalities by growth rate**
- Compare first vs latest snapshot per municipality: `(latest - first) / first × 100`
- Skip municipalities with 0 initial count (avoid division by zero)
- Sort descending, take 5

**3f. Bottom 5 declining municipalities**
- Same calculation as 3e, sort ascending, take 5 with negative growth

#### Task 4: Chart Fixes (Trendovi + Opština Detail)

**Files:**
- Modify: `lib/screens/trendovi/trendovi_screen.dart` — isCurved, x-axis, y-axis
- Modify: `lib/screens/opstine/opstina_detail_screen.dart` — isCurved, x-axis, y-axis, bottom labels
- Create: `lib/utils/chart_helpers.dart` — shared `abbreviateCount()` and date x-axis logic
- Modify: `test/screens/trendovi_screen_test.dart`
- Create: `test/screens/opstina_detail_screen_test.dart` (currently missing — coverage gap from MEMORY.md)

**Changes:**
- `isCurved: true` → `isCurved: false` on both charts
- X-value: snapshot date as milliseconds since epoch (proportional temporal spacing)
- Y-axis: left labels with abbreviated counts ("450K", "1.2M")
- Bottom labels on Opština detail (currently hidden)
- Date label positioning adjusted for proportional x-axis

#### Task 5: Mapa + O aplikaciji Fixes

**Files:**
- Modify: `lib/screens/mapa/mapa_screen.dart` — add explanatory note for 0-count overlay
- Modify: `test/screens/mapa_screen_test.dart` — test 0-count note
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart` — tappable link
- Modify: `test/screens/o_aplikaciji_screen_test.dart` — test link presence
- Modify: `pubspec.yaml` — add `url_launcher` dependency

**Mapa:** In `_MunicipalityOverlay`, when `totalActive == 0`, show note: "Podaci za ovu opštinu mogu biti objedinjeni sa drugom opštinom"

**O aplikaciji:** Replace plain "data.gov.rs" text with tappable link to `https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/`. Style with primary color + underline.

---

### Phase 3: Integration

#### Task 6: Final Verification

- `flutter test` — all tests pass
- `flutter analyze` — no issues
- Manual device/emulator walkthrough of all 5 screens
- Verify: CSV parsing correct for all 12 snapshots
- Verify: municipality names display correctly (no `?` characters)
- Verify: Opštine navigation works for all municipalities including diacritics
- Verify: charts show proportional date spacing with straight lines
- Verify: grey map polygons show explanatory note on tap
- Verify: data source link opens in browser

## Key Risks

| Risk | Mitigation |
|---|---|
| Parser rewrite breaks all data loading | Comprehensive TDD; all existing csv_parser_test fixtures serve as regression |
| data_loader_test fixture uses fake headers | Update fixture to use real variant headers as part of Task 1 |
| URL-encoding breaks existing navigation tests | Test round-trip explicitly |
| fl_chart proportional x-axis with clustered dates | May need minimum spacing; test with actual 12-snapshot distribution |
| GeoJSON name resolution misses some municipalities | Audit step in Task 5; explanatory note covers gaps |
