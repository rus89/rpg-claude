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

### Open items

- Internet permission missing from main AndroidManifest.xml — only in debug manifest. Will fail in release builds.
- GADM GeoJSON compound name matching (e.g. "MaloCrniće" vs "Malo Crniće") may cause some municipalities to render grey on the map. Needs validation against real data.
- Tile layer `ClientException` logs in tests are noisy but harmless. Could be suppressed if needed.
