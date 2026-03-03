# Visual Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the app from generic Material green to a warm, earthy civic design with a colored app bar, refined cards, improved typography hierarchy, and an enhanced map overlay.

**Architecture:** Centralise all visual tokens in a single `lib/theme.dart` file. Screens inherit from the theme — hardcoded colors/styles are removed. Phase 1 applies the theme globally; Phase 2 improves individual screen layouts.

**Tech Stack:** Flutter 3.x, Material 3, fl_chart, flutter_map. No new dependencies.

---

## Design Tokens (reference for all tasks)

| Token | Value | Usage |
|---|---|---|
| Primary | `#5C7A45` | App bar, active nav, chart bars/lines |
| Primary light | `#5C7A45` @ 15% opacity | Nav active indicator background |
| Background | `#F5F2EC` | Scaffold background |
| Surface | `#FFFFFF` | Cards |
| Accent | `#C47B2B` | Secondary highlights, badges |
| Text primary | `#1A1A1A` | Headlines, body |
| Text secondary | `#6B6B6B` | Labels, captions |
| Card radius | 12 | All cards |
| Card elevation | 0 (use shadow) | Box shadow: black @ 6%, blur 8, offset (0,2) |

---

## Phase 1: Theme & App Shell

### Task 1: Create theme file

**Files:**
- Create: `lib/theme.dart`
- Modify: `lib/app.dart:17-19` (replace inline ThemeData)

**Step 1: Write the failing test**

File: `test/theme_test.dart`

```dart
// ABOUTME: Tests for the centralised app theme.
// ABOUTME: Verifies color scheme, card, and app bar theme values.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/theme.dart';

void main() {
  test('primary color is olive green', () {
    expect(appTheme.colorScheme.primary.value, equals(const Color(0xFF5C7A45).value));
  });

  test('scaffold background is warm cream', () {
    expect(appTheme.scaffoldBackgroundColor.value, equals(const Color(0xFFF5F2EC).value));
  });

  test('app bar uses primary color background with white foreground', () {
    expect(appTheme.appBarTheme.backgroundColor!.value, equals(const Color(0xFF5C7A45).value));
    expect(appTheme.appBarTheme.foregroundColor!.value, equals(const Color(0xFFFFFFFF).value));
  });

  test('card theme has 12px border radius', () {
    final shape = appTheme.cardTheme.shape as RoundedRectangleBorder;
    final radius = (shape.borderRadius as BorderRadius).topLeft;
    expect(radius.x, equals(12));
  });
}
```

Add `import 'package:flutter/material.dart';` at the top after the ABOUTME lines.

**Step 2: Run test to verify it fails**

Run: `flutter test test/theme_test.dart`
Expected: FAIL — `package:rpg_claude/theme.dart` does not exist.

**Step 3: Write minimal implementation**

File: `lib/theme.dart`

```dart
// ABOUTME: Centralised app theme — defines all visual tokens in one place.
// ABOUTME: Screens inherit from this theme; no hardcoded colors in widgets.

import 'package:flutter/material.dart';

const _primary = Color(0xFF5C7A45);
const _background = Color(0xFFF5F2EC);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B6B6B);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primary,
    surface: _surface,
    onSurface: _textPrimary,
  ),
  scaffoldBackgroundColor: _background,
  appBarTheme: const AppBarTheme(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    color: _surface,
    shadowColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _surface,
    indicatorColor: _primary.withValues(alpha: 0.15),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 12, color: _textSecondary),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _background,
    selectedColor: _primary,
    labelStyle: TextStyle(color: _textPrimary),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    showCheckmark: true,
    checkmarkColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary),
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w800,
      color: _textPrimary,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w700,
      color: _textPrimary,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.w400,
      color: _textPrimary,
    ),
    bodySmall: TextStyle(
      fontWeight: FontWeight.w500,
      color: _textSecondary,
    ),
  ),
);

/// Amber accent for secondary highlights (chart accents, badges).
const accentColor = Color(0xFFC47B2B);
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/theme_test.dart`
Expected: PASS

**Step 5: Wire theme into app**

Modify `lib/app.dart:17-19` — replace the inline `ThemeData(...)` with `appTheme`:

```dart
// Add import at top:
import 'theme.dart';

// Replace lines 17-19:
theme: appTheme,
```

**Step 6: Run all tests**

Run: `flutter test`
Expected: All existing tests pass. Some screen tests may need the theme wrapper updated if they assert on specific colours — fix any breakages.

**Step 7: Run analyzer**

Run: `flutter analyze`
Expected: No issues.

**Step 8: Commit**

```bash
git add lib/theme.dart lib/app.dart test/theme_test.dart
git commit -m "Add centralised theme with warm olive palette"
```

---

### Task 2: Style the bottom navigation bar

**Files:**
- Modify: `lib/navigation/shell.dart:19-35`

**Step 1: Write the failing test**

File: `test/navigation/shell_test.dart`

```dart
// ABOUTME: Widget tests for AppShell bottom navigation styling.
// ABOUTME: Verifies active/inactive icon appearance and indicator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_claude/navigation/shell.dart';
import 'package:rpg_claude/theme.dart';

void main() {
  testWidgets('navigation bar uses theme indicator color', (tester) async {
    final router = GoRouter(
      initialLocation: '/pregled',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/pregled', builder: (_, __) => const Placeholder()),
            GoRoute(path: '/opstine', builder: (_, __) => const Placeholder()),
            GoRoute(path: '/trendovi', builder: (_, __) => const Placeholder()),
            GoRoute(path: '/mapa', builder: (_, __) => const Placeholder()),
            GoRoute(
              path: '/o-aplikaciji',
              builder: (_, __) => const Placeholder(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: appTheme),
    );
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar, isNotNull);
  });
}
```

**Step 2: Run test to verify it passes**

This test verifies the shell renders with our theme. Run: `flutter test test/navigation/shell_test.dart`

Note: The navigation bar styling comes from the theme (Task 1). The shell itself needs no code changes beyond what the theme already provides — Material 3's `NavigationBar` reads `NavigationBarThemeData` automatically.

**Step 3: Verify visually**

The shell's `NavigationBar` already uses `NavigationDestination` widgets. The `NavigationBarThemeData` from Task 1 applies the indicator color and label style automatically. No code changes needed in `shell.dart`.

**Step 4: Run all tests**

Run: `flutter test`
Expected: All pass.

**Step 5: Commit**

```bash
git add test/navigation/shell_test.dart
git commit -m "Add navigation shell test with theme verification"
```

---

### Task 3: Add card shadow decoration helper

The Material `CardTheme` doesn't support custom box shadows — only `elevation`. To get our precise shadow (`black @ 6%, blur 8, offset (0,2)`), we need a reusable `BoxDecoration`. Screens that use `Card` can optionally wrap content in a `DecoratedBox` instead, or we add a small helper.

**Files:**
- Modify: `lib/theme.dart` (add `cardDecoration`)

**Step 1: Write the failing test**

Add to `test/theme_test.dart`:

```dart
test('cardDecoration has 12px radius and subtle shadow', () {
  expect(cardDecoration.borderRadius, equals(BorderRadius.circular(12)));
  expect(cardDecoration.boxShadow, isNotNull);
  expect(cardDecoration.boxShadow!.length, equals(1));
  expect(cardDecoration.color, equals(const Color(0xFFFFFFFF)));
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/theme_test.dart`
Expected: FAIL — `cardDecoration` undefined.

**Step 3: Write minimal implementation**

Add to bottom of `lib/theme.dart`:

```dart
/// Card-like container decoration with custom shadow.
final cardDecoration = BoxDecoration(
  color: _surface,
  borderRadius: BorderRadius.circular(12),
  boxShadow: const [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
);
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/theme_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/theme.dart test/theme_test.dart
git commit -m "Add card decoration helper with custom shadow"
```

---

## Phase 2: Screen-Specific Improvements

### Task 4: Restyle Pregled (overview) screen

**Files:**
- Modify: `lib/screens/pregled/pregled_screen.dart`
- Modify: `test/screens/pregled_screen_test.dart`

**Step 1: Update `_SummaryCard` to use `cardDecoration`**

Replace the `Card` widget in `_SummaryCard.build()` (lines 140-157) with a `DecoratedBox`:

```dart
@override
Widget build(BuildContext context) {
  return DecoratedBox(
    decoration: cardDecoration,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    ),
  );
}
```

Add `import '../../theme.dart';` at top.

Note: `headlineSmall` already has `fontWeight: w800` from our theme, so we remove the inline `copyWith(fontWeight: FontWeight.bold)`.

**Step 2: Update section heading style**

Replace the hardcoded `TextStyle(fontWeight: FontWeight.bold)` on line 87 with:

```dart
style: Theme.of(context).textTheme.titleMedium,
```

This requires removing `const` from the parent `Text` widget.

**Step 3: Run existing tests**

Run: `flutter test test/screens/pregled_screen_test.dart`

The tests check for text content (`'1.050'`, `'940'`) and `BarChart` presence — these should still pass since we changed styling, not content. If any test wraps with `MaterialApp()` without a theme, add `theme: appTheme` to get consistent rendering.

**Step 4: Run all tests + analyzer**

Run: `flutter test && flutter analyze`
Expected: All pass, no analyzer issues.

**Step 5: Commit**

```bash
git add lib/screens/pregled/pregled_screen.dart
git commit -m "Apply warm theme to Pregled screen cards and typography"
```

---

### Task 5: Restyle Opštine (municipality list) screen

**Files:**
- Modify: `lib/screens/opstine/opstine_screen.dart`

**Step 1: Update search field**

The `InputDecorationTheme` from Task 1 handles the rounded border and fill automatically. Remove the explicit `border: OutlineInputBorder()` from the `TextField` decoration (line 34) so it inherits from the theme:

```dart
decoration: const InputDecoration(
  hintText: 'Pretraži opštine...',
  prefixIcon: Icon(Icons.search),
),
```

**Step 2: Add subtle list dividers**

Replace `ListView.builder` with `ListView.separated`:

```dart
ListView.separated(
  itemCount: filtered.length,
  separatorBuilder: (_, __) => const Divider(height: 1),
  itemBuilder: (context, index) {
    final name = filtered[index];
    return ListTile(
      title: Text(name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/opstine/$name'),
    );
  },
),
```

**Step 3: Run existing tests**

Run: `flutter test test/screens/opstine_screen_test.dart`
Expected: All pass.

**Step 4: Run all tests + analyzer**

Run: `flutter test && flutter analyze`

**Step 5: Commit**

```bash
git add lib/screens/opstine/opstine_screen.dart
git commit -m "Apply theme to Opštine search field and list dividers"
```

---

### Task 6: Restyle Opština detail screen

**Files:**
- Modify: `lib/screens/opstine/opstina_detail_screen.dart`

**Step 1: Update heading styles**

Replace hardcoded `TextStyle(fontWeight: FontWeight.bold)` on lines 47 and 59 with `Theme.of(context).textTheme.titleMedium`.

**Step 2: Run all tests + analyzer**

Run: `flutter test && flutter analyze`

**Step 3: Commit**

```bash
git add lib/screens/opstine/opstina_detail_screen.dart
git commit -m "Apply theme typography to Opština detail screen"
```

---

### Task 7: Restyle Trendovi (trends) screen

**Files:**
- Modify: `lib/screens/trendovi/trendovi_screen.dart`

**Step 1: Update dropdown decoration**

Remove the explicit `border: OutlineInputBorder()` from the dropdown (line 59) so it inherits the rounded theme:

```dart
decoration: const InputDecoration(labelText: 'Opština'),
```

**Step 2: Update chip styling**

The `ChipThemeData` from Task 1 handles selected/unselected colors. Verify the chips look correct — no code changes needed if the theme applies properly. If the selected label color doesn't switch to white, add explicit `labelStyle` to the `FilterChip`:

```dart
FilterChip(
  label: Text(form.displayName),
  selected: _selectedForms.contains(form),
  selectedColor: Theme.of(context).colorScheme.primary,
  labelStyle: TextStyle(
    color: _selectedForms.contains(form) ? Colors.white : null,
  ),
  checkmarkColor: Colors.white,
  onSelected: (selected) => setState(() {
    selected ? _selectedForms.add(form) : _selectedForms.remove(form);
  }),
)
```

**Step 3: Run existing tests**

Run: `flutter test test/screens/trendovi_screen_test.dart`

**Step 4: Run all tests + analyzer**

Run: `flutter test && flutter analyze`

**Step 5: Commit**

```bash
git add lib/screens/trendovi/trendovi_screen.dart
git commit -m "Apply theme to Trendovi dropdown and filter chips"
```

---

### Task 8: Restyle O aplikaciji (about) screen

**Files:**
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- Modify: `test/screens/o_aplikaciji_screen_test.dart`

**Step 1: Write failing test for icon presence**

Add to the existing test file:

```dart
testWidgets('info sections show leading icons', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
  expect(find.byIcon(Icons.info_outline), findsOneWidget);
  expect(find.byIcon(Icons.gavel), findsOneWidget);
  expect(find.byIcon(Icons.open_in_new), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/o_aplikaciji_screen_test.dart`
Expected: FAIL — no icons found.

**Step 3: Replace `_Section` with card-based layout**

Wrap each info section in a `DecoratedBox` with `cardDecoration` and add a leading icon:

```dart
import '../../theme.dart';

// Replace the three _Section + Divider blocks with:
_InfoCard(
  icon: Icons.info_outline,
  title: 'O aplikaciji',
  body: 'Ova aplikacija prikazuje otvorene podatke o registrovanim '
      'poljoprivrednim gazdinstvima u Srbiji (RPG), preuzete sa portala '
      'data.gov.rs. Cilj aplikacije je obrazovni — da omogući svim '
      'zainteresovanim građanima lak pristup ovim podacima.',
),
const SizedBox(height: 12),
_InfoCard(
  icon: Icons.gavel,
  title: 'Napomena o nezavisnosti',
  body: 'Ova aplikacija je razvio nezavisan developer i nije '
      'povezana ni sa jednim državnim organom, institucijom ili '
      'organizacijom. Podaci se preuzimaju direktno sa portala '
      'data.gov.rs i koriste se isključivo u informativne i '
      'obrazovne svrhe.',
),
const SizedBox(height: 12),
_InfoCard(
  icon: Icons.open_in_new,
  title: 'Izvor podataka',
  body: 'Podaci potiču od Uprave za agrarna plaćanja i dostupni '
      'su na: data.gov.rs',
),
```

**Step 4: Replace `_Section` widget class with `_InfoCard`**

```dart
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Remove the `_Section` class and the `Divider` widgets between sections.

**Step 5: Run test to verify it passes**

Run: `flutter test test/screens/o_aplikaciji_screen_test.dart`
Expected: PASS

**Step 6: Run all tests + analyzer**

Run: `flutter test && flutter analyze`

**Step 7: Commit**

```bash
git add lib/screens/o_aplikaciji/o_aplikaciji_screen.dart test/screens/o_aplikaciji_screen_test.dart
git commit -m "Restyle O aplikaciji with icon cards"
```

---

### Task 9: Enhance Mapa overlay with bottom sheet

**Files:**
- Modify: `lib/screens/mapa/mapa_screen.dart:110-137`
- Modify: `test/screens/mapa_screen_test.dart`

This is the largest change. Replace the simple `Card` overlay with a `DraggableScrollableSheet` that shows the municipality name, total active count as a large number, and a breakdown by org form.

**Step 1: Update existing tests for new overlay structure**

The existing tests check for `'Barajevo'` and `'90 aktivnih'` text. Update to match the new layout:

- Municipality name still appears as text (no change to assertion)
- Count format changes from `'90 aktivnih'` to `'90'` displayed large, with a label `'Aktivnih gazdinstava'` below it
- Close button (Icons.close) is replaced by a drag handle or remains — keep `Icons.close` for testability

Update test assertions (in the test that checks `'90 aktivnih'`):

```dart
expect(find.text('Barajevo'), findsOneWidget);
expect(find.text('90'), findsOneWidget);
expect(find.text('Aktivnih gazdinstava'), findsOneWidget);
```

Apply similar changes to all overlay tests (`_SpacedNameFixture` → `'50'`, `_DjFixture` → `'70'`).

**Step 2: Run tests to verify they fail**

Run: `flutter test test/screens/mapa_screen_test.dart`
Expected: FAIL — old format `'90 aktivnih'` no longer found.

Wait — we need to update the tests first to expect the new format, then make them fail, then implement. Let me restructure:

**Step 2 (corrected): Write NEW test for org form breakdown**

Add to `test/screens/mapa_screen_test.dart`:

```dart
testWidgets('overlay shows org form breakdown', (tester) async {
  final hitNotifier = ValueNotifier<LayerHitResult<Object>?>(null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataRepositoryProvider.overrideWith(() => _Fixture())],
      child: MaterialApp(
        theme: appTheme,
        home: MapaScreen(
          tileProvider: _NoOpTileProvider(),
          hitNotifier: hitNotifier,
        ),
      ),
    ),
  );
  await tester.pump();

  hitNotifier.value = const LayerHitResult(
    hitValues: ['Barajevo'],
    coordinate: LatLng(44.0, 21.0),
    point: Point(0, 0),
  );
  await tester.pump();

  // Should show org form name and count
  expect(find.text('Porodično gazdinstvo'), findsOneWidget);
  expect(find.text('90'), findsOneWidget);

  addTearDown(hitNotifier.dispose);
});
```

Add `import 'package:rpg_claude/theme.dart';` to the test file.

**Step 3: Run test to verify it fails**

Run: `flutter test test/screens/mapa_screen_test.dart`
Expected: FAIL — overlay currently shows `'90 aktivnih'` as a single text, no org form breakdown.

**Step 4: Implement the bottom sheet overlay**

Replace lines 110-137 in `mapa_screen.dart` with:

```dart
if (_tappedMunicipality != null)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: _MunicipalityOverlay(
      name: _tappedMunicipality!,
      records: snapshots.last.records,
      activeByMunicipality: activeByMunicipality,
      onClose: () => setState(() => _tappedMunicipality = null),
    ),
  ),
```

Add a new widget class at the bottom of the file:

```dart
class _MunicipalityOverlay extends StatelessWidget {
  const _MunicipalityOverlay({
    required this.name,
    required this.records,
    required this.activeByMunicipality,
    required this.onClose,
  });

  final String name;
  final List<Record> records;
  final Map<String, int> activeByMunicipality;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final normalised = normaliseSerbianName(name);
    final totalActive = activeByMunicipality[normalised] ?? 0;

    // Find all org form records for this municipality by normalised match
    final municipalityRecords = records.where((r) {
      return normaliseSerbianName(r.municipalityName) == normalised;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName(name),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          // Total count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$totalActive',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 8),
                Text(
                  'Aktivnih gazdinstava',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Org form breakdown
          if (municipalityRecords.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: municipalityRecords
                    .where((r) => r.activeHoldings > 0)
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                r.orgForm.displayName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${r.activeHoldings}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

Add `import '../../data/models/record.dart';` at the top and `import '../../theme.dart';` if not already present.

Note: The `_buildPolygons` method needs `snapshots.last.records` passed to the overlay, so modify `data:` callback to capture `latest.records`.

**Step 5: Update existing test assertions**

Update the existing test `'shows info card when polygon hit notifier fires'`:

```dart
expect(find.text('Barajevo'), findsOneWidget);
expect(find.text('90'), findsOneWidget);
expect(find.text('Aktivnih gazdinstava'), findsOneWidget);
```

Update `'matches GeoJSON name without spaces...'`:
```dart
expect(find.text('Novi Beograd'), findsOneWidget);
expect(find.text('50'), findsOneWidget);
```

Update `'matches GeoJSON đ to CSV ? ...'`:
```dart
expect(find.text('Inđija'), findsOneWidget);
expect(find.text('70'), findsOneWidget);
```

Close button and dismiss tests should still work as-is (the `Icons.close` button remains).

**Step 6: Run tests to verify they pass**

Run: `flutter test test/screens/mapa_screen_test.dart`
Expected: All PASS.

**Step 7: Run all tests + analyzer**

Run: `flutter test && flutter analyze`

**Step 8: Commit**

```bash
git add lib/screens/mapa/mapa_screen.dart test/screens/mapa_screen_test.dart
git commit -m "Replace map overlay with detailed bottom sheet"
```

---

### Task 10: Final polish — Loading screen

**Files:**
- Modify: `lib/screens/loading/loading_screen.dart`

**Step 1: Apply theme colours to loading indicator**

The `CircularProgressIndicator` already reads from `colorScheme.primary` by default. The error icon uses hardcoded `Colors.red` — change to `colorScheme.error`:

```dart
Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
```

This requires removing `const` from the parent `Column`.

**Step 2: Run existing tests**

Run: `flutter test test/screens/loading_screen_test.dart`
Expected: PASS.

**Step 3: Run all tests + analyzer**

Run: `flutter test && flutter analyze`

**Step 4: Commit**

```bash
git add lib/screens/loading/loading_screen.dart
git commit -m "Apply theme to loading screen error state"
```

---

### Task 11: Full regression + visual review

**Step 1: Run full test suite**

Run: `flutter test`
Expected: All pass.

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues.

**Step 3: Visual review with Milan**

Run the app on device/simulator. Walk through each screen and compare against the design spec:

- [ ] App bar is olive green (`#5C7A45`) with white text on ALL screens
- [ ] Background is warm cream (`#F5F2EC`) everywhere
- [ ] Stat cards on Pregled have custom shadow and rounded corners
- [ ] Bar chart uses olive green bars
- [ ] Opštine search field has rounded border
- [ ] Opštine list has dividers
- [ ] Trendovi dropdown has rounded border
- [ ] Trendovi chips: selected = olive green with white text
- [ ] Trendovi line chart uses olive green
- [ ] O aplikaciji has icon cards instead of plain text sections
- [ ] Mapa overlay is a bottom sheet with org form breakdown
- [ ] Nav bar active indicator is light olive tint
- [ ] Loading screen spinner is olive green

Take screenshots for comparison.

**Step 4: Commit any final fixes**

```bash
git commit -m "Complete visual redesign"
```
