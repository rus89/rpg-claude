# Project Journal

## 2026-02-27: Completed Tasks 10-14 + bug fixes

### Bug fixes

**Router redirect on error (commit 0465a8f):** The GoRouter redirect used `isLoading` to decide when to leave the loading screen. `isLoading` is false for both `AsyncData` and `AsyncError`, so on fetch failure the user was immediately redirected to `/pregled` and never saw the retry button. Fixed by using `hasValue` instead — only redirect when data has actually loaded.

**Resilient CSV loading (commit b87336a):** `DataLoader.loadAll` used `Future.wait` which fails fast — one broken URL (404) killed the entire load. Changed to catch per-source errors and skip them, only throwing if ALL sources fail. Made `sources` and `fetchBytes` injectable for testability.

**Test CSV fixture (commit 3ee00e8):** Reviewer found that `_csvContent` in data_loader_test had 7 columns but `CsvParser` requires 8 (missing org form label at index 5). Every data row was silently skipped, producing empty snapshots. Tests passed by coincidence because they only checked `snapshots.length` and dates, not record contents. Fixed the fixture and added record content assertions.

### Tasks completed

- **Task 10 (Opštine):** Searchable municipality list with detail screen showing org form breakdown and trend line chart. Route `/opstine/:name` added.
- **Task 11 (Trendovi):** Line chart with municipality dropdown and org form filter chips. Used `initialValue` instead of deprecated `value` on `DropdownButtonFormField`.
- **Task 12 (Mapa):** Choropleth map using GADM GeoJSON (Level 2). Renders polygons coloured by active holdings count. GeoJSON `NAME_2` property has no spaces in names (e.g. "MaloCrniće") — normalisation handles this. Map renders immediately with tile layer; polygon layer added conditionally when GeoJSON finishes async loading.
- **Task 13 (O aplikaciji):** Static content with disclaimer, data source credit, and tab guide.
- **Task 14 (Integration test):** End-to-end test on Android — passed. Data loads from data.gov.rs in ~90 seconds.

### Lessons learned

- `AsyncValue.isLoading` is only true during loading — NOT a reliable check for "not yet loaded". Use `hasValue` for "data successfully loaded".
- GADM GeoJSON NAME_2 values have no spaces in compound names. The `_normalise` function strips diacritics but doesn't handle missing spaces — potential matching issue for compound municipality names.
- `rootBundle.loadString` is async; in widget tests the asset won't be available after a single `pump()`. Design screens to render progressively (show map immediately, add polygon layer when GeoJSON loads) rather than blocking on the asset.
- Test fixtures must match the real data format exactly. Silent row-skipping in parsers makes this easy to miss — always assert on record content, not just collection length.
- data.gov.rs URLs can go stale (404). The Aug 2018 CSV was removed at some point. Milan manually fixed the URL.
- Android internet permission: present in debug manifest but not main. Works for `flutter run` but would fail in release builds.

## 2026-02-27: Fix map diacritics and display names (branch: fix/map-diacritics-and-display-names)

### Root cause discovery

Milan reported grey municipalities with diacritics on the map, and glued compound names in the overlay. Initial hypothesis was Unicode decomposed vs precomposed forms — **wrong**. Actual root cause: **CSV files are Windows-1250 encoded**, and the `latin1.decode` fallback was corrupting Serbian diacritics (bytes 0x80–0x9F map differently in Latin-1 vs W-1250).

Additional data quality issue: the government CSV stores đ (d with stroke) as literal `?` character (byte 0x3F). This is baked into the source data.

### Fixes applied

1. **Windows-1250 codec** (`lib/data/windows1250.dart`): 256-entry byte→Unicode lookup table. No external dependency needed.
2. **CSV parser**: Changed encoding fallback from `latin1.decode` to `windows1250Decode`.
3. **Normaliser**: Changed đ handling from đ→dj to stripping both đ and ?, so GeoJSON names (with đ) match CSV names (with ?).
4. **Map overlay**: Build display name lookup from CSV municipality names (proper spacing). Replace ? with đ for display. Overlay now shows "Nova Varoš" instead of "NovaVaroš".

### Lessons learned

- Government CSV data from data.gov.rs uses Windows-1250, NOT UTF-8 or Latin-1. Always check raw byte values when debugging encoding issues.
- `latin1.decode` maps bytes 0x80–0x9F to C1 control characters which are invisible in text rendering — makes the corruption hard to spot visually.
- đ (U+0111) has no canonical Unicode decomposition, unlike č/š/ž/ć. NFD decomposition approach wouldn't have helped for đ anyway.
- CORS works fine for data.gov.rs from web (tested with `flutter run -d chrome`).

### Open items

- Internet permission missing from main AndroidManifest.xml — only in debug manifest. Will fail in release builds.
- Tile layer `ClientException` logs in tests are noisy but harmless. Could be suppressed if needed.
- Milan needs to re-test the map on device to verify all municipalities now render with colour.
