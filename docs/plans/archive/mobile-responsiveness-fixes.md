# Plan: Mobile Responsiveness Fixes

## Context

Testing on Samsung Galaxy S24 Ultra revealed several responsive layout issues. The app was primarily designed/tested on tablet-sized screens — mobile viewports expose overflow and sizing problems across multiple screens.

---

## Fix 1: Pregled — Summary Card Numbers Overflowing

**Problem:** Numbers like "508.051" break into two lines because `headlineSmall` (24px) is too large for narrow cards in a 3-column Row.

**File:** `lib/screens/pregled/pregled_screen.dart` (lines 700-749, `_SummaryCard`)

**Fix:** Wrap the value `Text` widget in a `FittedBox` with `fit: BoxFit.scaleDown` so large numbers shrink to fit the available width instead of wrapping.

```dart
FittedBox(
  fit: BoxFit.scaleDown,
  alignment: Alignment.centerLeft,
  child: Text(value, style: Theme.of(context).textTheme.headlineSmall),
),
```

---

## Fix 2: Pregled — Chart Tooltip Backgrounds Overlapping

**Problem:** Bar chart tooltips (above each bar) overlap each other on mobile because the bars are closer together. Tooltip text is hardcoded at `fontSize: 11`.

**File:** `lib/screens/pregled/pregled_screen.dart` (lines 350-368 and similar)

**Fix:** Scale tooltip font size based on screen width. Use a smaller font on mobile:

```dart
final tooltipFontSize = isDesktop(context) ? 11.0 : 9.0;
```

Also add `fitInsideHorizontally: true` to `BarTouchTooltipData` to prevent horizontal overflow.

---

## Fix 3: Trendovi & Mapa — SegmentedButton Overflowing

**Problem:** `SegmentedButton` labels break into multiple rows on mobile. Especially bad on Mapa where labels are longer ("Prosečna starost", "Veličina (ha)").

**Files:**
- `lib/screens/trendovi/trendovi_screen.dart` (lines 103-122)
- `lib/screens/mapa/mapa_screen.dart` (lines 213-238)

**Fix (Trendovi):** Wrap `SegmentedButton` in `FittedBox(fit: BoxFit.scaleDown)` — labels are already short enough.

**Fix (Mapa):** Shorten labels AND wrap in FittedBox as safety net:
- "Gazdinstva" → keep
- "Veličina (ha)" → "Veličina"
- "Prosečna starost" → "Starost"
- "% < 40 god." → "< 40 god."

Then wrap in `FittedBox(fit: BoxFit.scaleDown)` for very narrow screens.

---

## Fix 4: Trendovi — Dropdown Values Bold

**Problem:** Municipality dropdown items appear unnecessarily bold on mobile.

**File:** `lib/screens/trendovi/trendovi_screen.dart` (lines 124-137)

**Issue is the dropdown list items** (when opened), not the selected value display.

**Investigation:** Items use plain `Text(n)` with no explicit style. Material 3's dropdown menu items may inherit a bolder default style.

**Fix:** Explicitly set `style` on dropdown menu items to use normal weight:

```dart
DropdownMenuItem(
  value: n,
  child: Text(n, style: const TextStyle(fontWeight: FontWeight.w400)),
),
```

---

## Fix 5a: Mapa — Initial Zoom Too Tight on Mobile

**Problem:** Hardcoded `initialZoom: 7.0` works for tablets but crops North Serbia on mobile (narrower viewport). On tablets it's too zoomed out, showing neighbouring countries.

**File:** `lib/screens/mapa/mapa_screen.dart` (lines 144-148)

**Fix:** Use `CameraFit.bounds` instead of a fixed zoom to auto-fit Serbia's bounding box regardless of screen size:

```dart
options: MapOptions(
  initialCameraFit: CameraFit.bounds(
    bounds: LatLngBounds(
      const LatLng(42.23, 18.82),  // SW corner (approximate Serbia bounds)
      const LatLng(46.19, 23.01),  // NE corner
    ),
    padding: const EdgeInsets.all(16),
  ),
),
```

This replaces `initialCenter` + `initialZoom` and adapts to any screen size.

---

## Fix 5b: Mapa — Missing Zoom/Re-center Controls

**Problem:** No +/- zoom or re-center buttons on the map. Users can only pinch-to-zoom.

**File:** `lib/screens/mapa/mapa_screen.dart`

**Fix:** Add a `MapController` and position zoom/re-center buttons at the bottom-right of the Stack:

```dart
late final MapController _mapController;

// In initState:
_mapController = MapController();

// In Stack children:
Positioned(
  bottom: 16,
  right: 16,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FloatingActionButton.small(
        heroTag: 'zoom_in',
        onPressed: () => _mapController.move(
          _mapController.camera.center,
          _mapController.camera.zoom + 1,
        ),
        child: const Icon(Icons.add),
      ),
      const SizedBox(height: 8),
      FloatingActionButton.small(
        heroTag: 'zoom_out',
        onPressed: () => _mapController.move(
          _mapController.camera.center,
          _mapController.camera.zoom - 1,
        ),
        child: const Icon(Icons.remove),
      ),
      const SizedBox(height: 8),
      FloatingActionButton.small(
        heroTag: 'recenter',
        onPressed: () => _mapController.fitCamera(
          CameraFit.bounds(bounds: _serbiaBounds, padding: EdgeInsets.all(16)),
        ),
        child: const Icon(Icons.my_location),
      ),
    ],
  ),
),
```

Dispose `_mapController` in `dispose()`.

---

## Files to Modify

| File | Fixes |
|------|-------|
| `lib/screens/pregled/pregled_screen.dart` | #1 (FittedBox on card values), #2 (tooltip sizing) |
| `lib/screens/trendovi/trendovi_screen.dart` | #3 (FittedBox on SegmentedButton), #4 (dropdown text style) |
| `lib/screens/mapa/mapa_screen.dart` | #3 (FittedBox on SegmentedButton), #5a (bounds-based zoom), #5b (zoom controls) |

---

## Verification

- `flutter analyze` — clean
- `flutter test` — all 205 tests pass
- Manual on Galaxy S24 Ultra:
  - Pregled: card numbers fit on one line, tooltips don't overlap
  - Trendovi: SegmentedButton fits, dropdown items not bold
  - Mapa: Serbia fits viewport, zoom/re-center buttons work, metric selector fits
- Manual on tablet: verify nothing regressed (Serbia still fits nicely, cards look good)
