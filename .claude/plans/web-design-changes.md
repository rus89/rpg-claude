# Plan: Responsive Web Layout — Full Website Feel

## Context

The app is 100% mobile-optimized with zero responsive logic. On web/desktop it looks like a phone app stretched across a browser window — bottom nav bar, narrow column layouts, fixed-size charts. Milan wants it to feel like a proper website on desktop while keeping mobile layout pixel-identical.

**No new dependencies required.** Everything uses `MediaQuery` and `LayoutBuilder` from Flutter core.

---

## Breakpoint Strategy

Single breakpoint — simple and sufficient for a data dashboard:

| Name | Width | Behaviour |
|------|-------|-----------|
| Mobile/Tablet | < 1024px | Current layout, unchanged (bottom nav, single-column) |
| Desktop | ≥ 1024px | Top nav, max-width container, multi-column where appropriate |

---

## Implementation Tasks

### Task 1: Breakpoint infrastructure

**Create `lib/layout/breakpoints.dart`:**
- `const double desktopBreakpoint = 1024;`
- `bool isDesktop(BuildContext context)` helper using `MediaQuery.sizeOf(context).width`

**Create `test/layout/breakpoints_test.dart`**

### Task 2: ScreenScaffold wrapper

**Create `lib/layout/screen_scaffold.dart`:**

A reusable widget that replaces raw `Scaffold` in every screen:
- **Mobile**: Renders `Scaffold(appBar: AppBar(title), body: content)` — identical to current
- **Desktop**: Renders just the body wrapped in `Center` → `ConstrainedBox(maxWidth: 1200)` with horizontal padding — no Scaffold, no AppBar (the shell handles the nav)
- Accepts `fullWidth: true` parameter for MapaScreen (skip max-width constraint)
- Accepts `title: String` for the AppBar text

**Create `test/layout/screen_scaffold_test.dart`**

### Task 3: Responsive AppShell (the big visual change)

**Modify `lib/navigation/shell.dart`:**
- **Mobile (< 768)**: Exactly current code — `Scaffold` with bottom `NavigationBar`
- **Desktop (≥ 768)**: `Scaffold` with a top navigation bar (in `appBar` or `body` top), no bottom nav
  - Top bar: App title on left, navigation links (TextButton style) on right
  - Active tab highlighted with primary colour

**Modify `lib/theme.dart`:** Add desktop top nav styling tokens.

**Update `test/navigation/shell_test.dart`:** Add desktop nav tests.

### Task 4: Migrate screens to ScreenScaffold (one at a time)

Replace raw `Scaffold` with `ScreenScaffold` in each screen. Order (simplest → most complex):

1. `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
2. `lib/screens/opstine/opstine_screen.dart`
3. `lib/screens/trendovi/trendovi_screen.dart`
4. `lib/screens/opstine/opstina_detail_screen.dart`
5. `lib/screens/pregled/pregled_screen.dart`
6. `lib/screens/mapa/mapa_screen.dart` (with `fullWidth: true`)

Run tests after each migration.

### Task 5: Desktop-specific layouts per screen

Screen-specific enhancements for desktop width:

| Screen | Desktop Enhancement |
|--------|-------------------|
| **PregledScreen** | Rankings in 3-column Row instead of vertical stack. Chart height 360px (from 240px). |
| **OpstinaDetailScreen** | Org form list + chart side by side in two-column layout. Chart height 280px (from 160px). |
| **TrendoviScreen** | Chart height 400px (from 280px). |
| **OAplikacijiScreen** | Info cards in 2-column grid. |
| **MapaScreen** | Constrain overlay width (max ~600px, centred). Map stays full-width. |
| **OpstineScreen** | Benefits from max-width container alone — no per-screen changes needed. |

### Task 6: Test adjustments

**No problem**: Flutter's default test surface is 800×600, which is < 1024px. Existing screen tests will naturally render in mobile mode — no changes needed to existing tests. Add separate desktop-width tests (≥ 1024px) for the new responsive behaviour.

---

## Files Summary

**New files (4):**
- `lib/layout/breakpoints.dart`
- `lib/layout/screen_scaffold.dart`
- `test/layout/breakpoints_test.dart`
- `test/layout/screen_scaffold_test.dart`

**Modified files (10):**
- `lib/navigation/shell.dart`
- `lib/theme.dart`
- `lib/screens/pregled/pregled_screen.dart`
- `lib/screens/opstine/opstine_screen.dart`
- `lib/screens/opstine/opstina_detail_screen.dart`
- `lib/screens/trendovi/trendovi_screen.dart`
- `lib/screens/mapa/mapa_screen.dart`
- `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- `test/navigation/shell_test.dart`
- 7 screen test files (test helper + width overrides)

---

## Verification

1. `flutter analyze` — clean
2. `flutter test` — all pass (existing + new)
3. Manual test at mobile width (< 1024px) — confirm pixel-identical to current
4. Manual test at desktop width (1200px+) — top nav, max-width content, multi-column layouts
5. Test at breakpoint boundary (1023px vs 1024px) — clean transition
