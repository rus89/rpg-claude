# Plan: Tester Feedback — Phase 1 (Rate, ASO, Feedback)

## Context

The paid testing engagement produced a feedback report (`docs/test/com.serbiaOpenData.rpg_claude_feedback.pdf`) flagging six enhancement areas. After triage, Milan selected three to ship in this round. Dark mode, English localisation, and onboarding are intentionally deferred; screenshots are being handled separately by Milan; performance/marketing items were too vague to action.

The three features this plan covers:

1. **Rate Your App** button in "O aplikaciji" — opens the Play Store listing.
2. **ASO polish** — update in-repo metadata copy + draft Play Store listing text.
3. **User feedback** tile in "O aplikaciji" — opens a pre-filled `mailto:` to `serbiaopendataapps@gmail.com`, with app version auto-stamped in the body so support can triage stale builds.

All features are Serbian-only. The app targets Android + web; iOS is not a target.

## Scope

**In:** the three features above, plus their tests and metadata updates.

**Out:** `in_app_review` native prompt (manual-button approach is what the testers asked for; programmatic prompting is a future phase), English localisation, onboarding flow, dark mode, performance/marketing, Play Store screenshots.

## Feature 1: Rate Your App button

### Behaviour
- New action tile rendered in `OAplikacijiScreen` between the info cards and the "Vodič kroz aplikaciju" section.
- Label: "Oceni aplikaciju", icon `Icons.star_rate`, subtitle `"Otvori Google Play prodavnicu"`.
- Tapping calls `launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.serbiaOpenData.rpg_claude'), mode: LaunchMode.externalApplication)` inside a `try` block. On `PlatformException` (or non-`true` return), show a `SnackBar` with the URL as plaintext so the user can copy it. Matches the pattern already used in [mapa_screen.dart:86-101](lib/screens/mapa/mapa_screen.dart#L86-L101).
- Hidden entirely when `kIsWeb == true` (no rating flow for web users) — gated via a pure helper (see **Web visibility seam** below), not an inline `if (kIsWeb)`, so the branch is unit-testable.

### Accessibility
- Wrap tap target in `Semantics(button: true, label: 'Oceni aplikaciju u Google Play prodavnici')`.
- Tap target minimum height 48dp — use `InkWell` inside a `Padding(all: 16)` so tap region covers the card.

### Implementation detail
- **Do not bloat `_InfoCard`.** Add a sibling `_ActionCard` widget (new, private, ~30 LOC) that takes `icon`, `title`, `subtitle`, `onTap`. Shared visual constants (`cardDecoration`) come from [lib/theme.dart:75-81](lib/theme.dart#L75-L81).
- Use `https://play.google.com/...` URL. On Android with the Play Store app installed, the system intent filter opens the Play Store app directly; no `market://` fast-path needed.

### Web visibility seam
Extract the web check into a top-level file-private helper so tests don't have to fake `kIsWeb`:

```dart
@visibleForTesting
bool shouldShowRateTile({bool isWeb = kIsWeb}) => !isWeb;
```

The tile's `if (shouldShowRateTile())` call reads `kIsWeb` by default; tests call `shouldShowRateTile(isWeb: true)` and `shouldShowRateTile(isWeb: false)` as a pure unit test.

## Feature 2: ASO polish

### In-repo changes
Update these files to align on a keyword-rich Serbian description (~150–200 chars, used by Flutter's web surface and PWA install prompts):

- [pubspec.yaml:2](pubspec.yaml#L2) — `description`
- [web/manifest.json:8](web/manifest.json#L8) — `description`
- [web/index.html:21](web/index.html#L21) — `<meta name="description">` content
- [web/index.html](web/index.html) — add OpenGraph `og:title`, `og:description`, `og:image` meta tags so shared web links render richly (reuse `icons/Icon-512.png`).

Suggested description to be reused across all four surfaces (Milan to approve final wording):

> "Pregledaj otvorene podatke o registrovanim poljoprivrednim gazdinstvima u Srbiji — mapa po opštinama, trendovi kroz vreme, i statistika po oblicima organizacije. Podaci sa data.gov.rs."

### Play Store listing (out-of-repo deliverable)
Drafted copy Milan will paste into Play Console — stored in this plan for reference, not in the repo. Milan iterates on the Console.

**Short description (≤80 chars), candidate:**
> "Otvoreni podaci o poljoprivrednim gazdinstvima Srbije — mapa, opštine, trendovi"

**Full description (≤4000 chars) outline — to be fleshed out by Milan:**
- Opening hook (1 sentence, what the app does)
- Three-to-four feature bullets (Pregled, Opštine, Trendovi, Mapa)
- Data source attribution + link to data.gov.rs
- Independence disclaimer (mirrors "Napomena o nezavisnosti" in the About screen)
- Keyword-natural closing paragraph (farmers, agricultural data, open data, Serbia, statistics, municipalities)

### Observation (no action required)
Web manifest `short_name` is "GeoAgro Srbija" (14 chars). Android launcher typically truncates past 12 chars. Already shipped in 1.0.1+4 — flagging only. If Milan wants to shorten ("GeoAgro" is 7 chars) it's a one-line change.

## Feature 3: User feedback tile

### Behaviour
- Second action tile next to the Rate button, using the same `_ActionCard` widget.
- Icon `Icons.mail_outline`, label "Prijavite grešku ili predlog", subtitle "Pošaljite poruku autoru".
- Tap opens a mailto URI built with `Uri(scheme: 'mailto', path: 'serbiaopendataapps@gmail.com', queryParameters: {'subject': 'GeoAgro Srbija — povratna informacija', 'body': 'Verzija aplikacije: v$version+$buildNumber\n\n'})`. Do **NOT** hand-concatenate the query string — Cyrillic characters in the body/subject break without proper encoding, which `Uri(...)` handles.
- Same `try`/`SnackBar`-fallback pattern as the rate button (user without a mail client gets the address in a copyable snackbar).
- Visible on both Android and web (mailto works in web browsers).

### Android package visibility (REQUIRED for mailto)
Android 11+ (API 30+) requires declaring intent queries for external schemes. The current [android/app/src/main/AndroidManifest.xml:40-45](android/app/src/main/AndroidManifest.xml#L40-L45) only declares `PROCESS_TEXT`, so `launchUrl('mailto:…')` throws `PlatformException` on real devices. Add a `SENDTO` query **before** coding the feature:

```xml
<queries>
    <!-- existing PROCESS_TEXT intent… -->
    <intent>
        <action android:name="android.intent.action.SENDTO" />
        <data android:scheme="mailto" />
    </intent>
</queries>
```

`https` (Play Store) generally resolves on Android 11+ without an explicit query under `url_launcher` ≥ 6.1.12, so the existing `data.gov.rs` link at [o_aplikaciji_screen.dart:161](lib/screens/o_aplikaciji/o_aplikaciji_screen.dart#L161) works. Only `mailto:` needs the query above.

### Version stamping
- Add `package_info_plus: ^10.1.0` to `pubspec.yaml` dependencies. (Latest stable on pub.dev as of 2026-04-22; the `PackageInfo.fromPlatform()` / `.version` / `.buildNumber` surface used here is unchanged from 8.x.)
- Fetch `PackageInfo.fromPlatform()` once at screen init via a `FutureBuilder` or read it before building the tile's `onTap`. Cache in a local `String` field so the handler reads synchronously when tapped.
- Format: `v${info.version}+${info.buildNumber}` → produces "v1.0.1+4" today.

## Dependencies (pubspec.yaml delta)

```yaml
dependencies:
  # existing entries…
  package_info_plus: ^10.1.0
```

No other additions. `url_launcher` is already present at [pubspec.yaml:21](pubspec.yaml#L21).

## Files to modify

| File | Change |
|---|---|
| [lib/screens/o_aplikaciji/o_aplikaciji_screen.dart](lib/screens/o_aplikaciji/o_aplikaciji_screen.dart) | Add `_ActionCard` widget + `shouldShowRateTile` helper + `_buildFeedbackUri` helper; insert two action cards between info cards and `Vodič`; load `PackageInfo` for feedback body; add try/catch + SnackBar fallback; **also** wrap the existing `_DataSourceLink.onTap` at line 161 with the same try/catch pattern for consistency. |
| [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) | Add `SENDTO`/`mailto` intent to `<queries>` (required for Android 11+ — see Feature 3). Label "GeoAgro Srbija" stays. |
| [pubspec.yaml](pubspec.yaml) | Update `description`; add `package_info_plus`. |
| [web/manifest.json](web/manifest.json) | Update `description`. |
| [web/index.html](web/index.html) | Update `<meta name="description">`; add OpenGraph tags. |
| [test/screens/o_aplikaciji_screen_test.dart](test/screens/o_aplikaciji_screen_test.dart) | **Modify existing** file — append new tests to the existing 7 tests; do not replace. See Tests section below. |

## Tests (TDD, per project rule)

Per [CLAUDE.md](CLAUDE.md) TDD rule, write tests first. The file [test/screens/o_aplikaciji_screen_test.dart](test/screens/o_aplikaciji_screen_test.dart) **already exists** with 7 tests — **append** to it, don't replace. Also wrap the test body in `MaterialApp(theme: appTheme, ...)` on new tests for theme consistency (existing tests use a bare `MaterialApp`; don't touch those).

New tests to add:

1. **Both action tiles render on non-web.** Wrap `OAplikacijiScreen` in `ProviderScope + MaterialApp(theme: appTheme)`, pump, assert `find.text('Oceni aplikaciju')` and `find.text('Prijavite grešku ili predlog')` each `findsOneWidget`.
2. **Web gating (unit test on the helper).** Call `shouldShowRateTile(isWeb: true)` → expect `false`; `shouldShowRateTile(isWeb: false)` → expect `true`. Pure Dart, no widget pump needed. The widget-level `kIsWeb` branch stays untested (acceptable — `kIsWeb` is compile-time in the VM and can't be toggled per-test).
3. **Accessibility: action tiles expose `Semantics(button: true)`.** Use `tester.getSemantics(find.byType(_ActionCard))` and assert `hasAction(SemanticsAction.tap)` + `isButton`.
4. **Unit test for `_buildFeedbackUri(PackageInfo info)` (extract as top-level private helper).** Pass a fake `PackageInfo(version: '1.0.2', buildNumber: '5', ...)`; assert `result.scheme == 'mailto'`, `result.path == 'serbiaopendataapps@gmail.com'`, and the decoded body starts with `'Verzija aplikacije: v1.0.2+5'`.

Do **not** mock `url_launcher_platform_interface`. Presence + semantics tests + pure-function unit tests catch the high-value regressions (tile removed, wrong label, wrong URL, wrong body).

Run `flutter test` — target: all existing tests still pass, plus new ones green. Confirm baseline count with `flutter test` before adding tests (do not trust a hardcoded number in this plan).

## Implementation order

1. Add `SENDTO`/`mailto` intent to `AndroidManifest.xml` `<queries>` (Feature 3 blocker — do this first so manual Android smoke test later doesn't throw).
2. Write failing tests (see Tests section).
3. Add `package_info_plus` to pubspec (`^10.1.0` — verified on pub.dev 2026-04-22), run `flutter pub get`.
4. Implement `_ActionCard` + `shouldShowRateTile` + `_buildFeedbackUri` + tile insertion.
5. Wrap existing `_DataSourceLink.onTap` at [o_aplikaciji_screen.dart:161](lib/screens/o_aplikaciji/o_aplikaciji_screen.dart#L161) with the same try/catch + SnackBar pattern (consistency).
6. Wire up `PackageInfo.fromPlatform()` loader.
7. Run `flutter test` — confirm all tests pass.
8. Update pubspec description, web/manifest.json description, web/index.html meta + OpenGraph tags.
9. Run `dart format .` and `flutter analyze` — both clean.
10. Manual smoke test: `flutter run -d chrome` (confirm feedback tile, no rate tile) and `flutter run` on Android device (confirm both tiles, tap each, verify Play Store opens and mail app opens with pre-filled body).
11. Commit as logical units:
    - `feat: add Rate app and feedback tiles to O aplikaciji`
    - `chore: add mailto intent query for Android 11+ package visibility`
    - `refactor: wrap data.gov.rs launchUrl with error fallback`
    - `chore: polish ASO description in pubspec, web manifest, and index.html`
12. Bump version in pubspec to `1.0.2+5`, tag per [CLAUDE.md](CLAUDE.md) Build Tagging rule, update Play Console listing copy from the drafts above.

## Verification

- **Unit + widget tests**: `flutter test` exits 0 with all new assertions passing.
- **Static analysis**: `flutter analyze` reports no issues; `dart format --set-exit-if-changed .` exits 0.
- **Manual — Android device** (must be API 30+ to validate package-visibility work):
  - Navigate to "O aplikaciji" tab. See two action cards after the info cards.
  - Tap "Oceni aplikaciju" → Play Store app opens at the GeoAgro Srbija listing (not an in-app webview, thanks to `LaunchMode.externalApplication`).
  - Tap "Prijavite grešku" → default mail app opens with recipient `serbiaopendataapps@gmail.com`, subject pre-filled, body starts with `"Verzija aplikacije: v1.0.2+5"`. If no email client installed, the SnackBar fallback appears instead.
  - Serbian characters in the subject render correctly (no `%` escapes visible in compose window).
  - Tap existing "data.gov.rs" link → still works; on a device with no browser, now shows the SnackBar fallback instead of silently throwing.
- **Manual — Web (`flutter run -d chrome`)**:
  - "O aplikaciji" tab shows only the feedback card (rate card hidden).
  - Tap feedback → browser opens the OS mail handler or webmail.
  - View source of built `web/index.html` → new OpenGraph tags present.
- **Metadata check**: `curl` the deployed web manifest.json and index.html, confirm updated descriptions.
