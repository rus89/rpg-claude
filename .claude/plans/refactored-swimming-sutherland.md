# Plan: Kosovo GeoJSON + Opštine Search Clear Button

## Context

Two independent features:
1. The current GeoJSON (`assets/geojson/serbia_municipalities.geojson`) covers Serbia without Kosovo. Kosovo municipalities exist in CSV data but have no map polygons. Milan will provide a Kosovo GeoJSON file (same FeatureCollection/NAME_2 format) to be merged into the existing file.
2. The Opštine search field has no way to clear the typed text — need an "X" button.

---

## Feature 1: Kosovo GeoJSON Merge

### What needs to happen
- Milan provides the Kosovo GeoJSON file
- Merge its `features` array into `serbia_municipalities.geojson`
- No code changes needed — the existing loading code in `data_provider.dart:24-39` and `mapa_screen.dart:56-63` reads from a single file and extracts NAME_2 from all features

### Steps
1. Receive Kosovo GeoJSON file from Milan
2. Merge features into `assets/geojson/serbia_municipalities.geojson`
3. Run `flutter test` to verify nothing breaks (NameResolver tests, map tests)
4. Verify map renders Kosovo municipalities correctly (manual check)

---

## Feature 2: Opštine Search Clear Button

### File to modify
- `lib/screens/opstine/opstine_screen.dart`

### Changes
1. Add a `TextEditingController` to `_OpstineScreenState`
2. Initialize it in state, dispose in `dispose()`
3. Assign the controller to the `TextField`
4. Add a `suffixIcon` to `InputDecoration` — an `IconButton` with `Icons.clear` that:
   - Clears the controller text
   - Resets `_query` to `''` via `setState`
   - Only visible when `_query.isNotEmpty`
5. Update test to verify the clear button appears and works

### Test changes
- `test/screens/opstine_screen_test.dart`: Add test that types in search, verifies clear button appears, taps it, and verifies the list is unfiltered again

---

## Verification
- `flutter analyze` — no warnings
- `flutter test` — all tests pass
- Manual: open Opštine, type a search term, tap X, confirm field clears and full list returns
- Manual: open Mapa, verify Kosovo municipalities render on the map (after GeoJSON merge)
