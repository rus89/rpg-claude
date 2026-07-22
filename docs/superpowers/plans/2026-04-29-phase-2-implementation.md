# Phase 2 — Privacy Policy, Native Rating, Dark Mode, Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship four user-visible features across two Play Store releases — Privacy Policy link, native `in_app_review` rating prompt, dark mode with system/light/dark toggle, and a 5-card first-launch onboarding flow with replay.

**Architecture:** A single `Preferences` wrapper around `shared_preferences` underpins all four features (theme mode, onboarding flag, app-open count, review-prompt cadence). Theme refactors a single global `appTheme` constant into `buildAppTheme(Brightness)` plus a `BuildContext` extension for `cardDecoration`. Onboarding adds a top-level `/onboarding` route to the existing GoRouter, with redirect logic gated by the `onboardingSeen` preference.

**Tech Stack:** Flutter 3.x, Dart 3.11, Riverpod (with `@Riverpod` codegen), GoRouter 14, `shared_preferences ^2.3.5`, `in_app_review ^2.0.10`, `package_info_plus ^10`.

**Source spec:** `.claude/plans/2026-04-29-phase-2-design.md`.

**Release split:**

| Release | Branch | Tag | Features |
| --- | --- | --- | --- |
| 1.0.3+6 | `main` | `v1.0.3+6` | Foundation + Privacy Policy tile + `in_app_review` |
| 1.0.4+9 | `feature/dark-mode-onboarding` | `v1.0.4+9` | Dark mode + onboarding + version label + chart x-axis fix |

Release 1 ships directly on `main` (small surface, low risk). Release 2 is a feature branch that PRs into `main` after the 1.0.3 build bakes on internal track.

> **Build number note:** `+7` was consumed by the `chore: bump version to 1.0.3+7` commit (riverpod 3.x migration patch on `main`, tagged `v1.0.3+7`) and `+8` by the targetSdk 36 patch (`1.0.3+8`, tagged `v1.0.3+8`), so Release 2 advances to `+9` to keep Play Console build numbers strictly monotonic.

---

## Task 1: Add `Preferences` wrapper and provider

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/data/preferences.dart`
- Create: `lib/providers/preferences_provider.dart`
- Test: `test/data/preferences_test.dart`

- [ ] **Step 1: Add `shared_preferences` dependency**

Edit `pubspec.yaml` — under `dependencies:`, add the line directly after `package_info_plus: ^10.1.0`:

```yaml
  shared_preferences: ^2.3.5
```

Then run:

```bash
flutter pub get
```

Expected: resolution succeeds, `pubspec.lock` updates.

- [ ] **Step 2: Write failing tests for `Preferences`**

Create `test/data/preferences_test.dart`:

```dart
// ABOUTME: Tests for the typed Preferences wrapper around shared_preferences.
// ABOUTME: Verifies defaults, roundtrip get/set, and ThemeMode encoding.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('themeModeName defaults to null when unset', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    expect(prefs.themeModeName, isNull);
  });

  test('themeModeName roundtrips light', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    await prefs.setThemeModeName('light');
    expect(prefs.themeModeName, 'light');
  });

  test('themeModeName roundtrips dark', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    await prefs.setThemeModeName('dark');
    expect(prefs.themeModeName, 'dark');
  });

  test('onboardingSeen defaults to false', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    expect(prefs.onboardingSeen, isFalse);
  });

  test('onboardingSeen roundtrips true', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingSeen(true);
    expect(prefs.onboardingSeen, isTrue);
  });

  test('appOpenCount defaults to 0 and increments', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    expect(prefs.appOpenCount, 0);
    await prefs.setAppOpenCount(1);
    expect(prefs.appOpenCount, 1);
  });

  test('lastReviewPromptDate roundtrips an ISO 8601 date', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    expect(prefs.lastReviewPromptDate, isNull);
    final d = DateTime.utc(2026, 4, 29);
    await prefs.setLastReviewPromptDate(d);
    expect(prefs.lastReviewPromptDate, d);
  });

  test('reviewPromptedForBuild roundtrips a build number string', () async {
    final prefs = Preferences(await SharedPreferences.getInstance());
    expect(prefs.reviewPromptedForBuild, isNull);
    await prefs.setReviewPromptedForBuild('6');
    expect(prefs.reviewPromptedForBuild, '6');
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/data/preferences_test.dart
```

Expected: all 8 tests fail with `Target of URI doesn't exist: 'package:rpg_claude/data/preferences.dart'`.

- [ ] **Step 4: Implement `Preferences`**

Create `lib/data/preferences.dart`:

```dart
// ABOUTME: Typed wrapper around SharedPreferences keyed by domain concepts.
// ABOUTME: Hides string keys and provides typed get/set per preference.

import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Preferences(this._prefs);

  static const _kThemeMode = 'themeMode';
  static const _kOnboardingSeen = 'onboardingSeen';
  static const _kAppOpenCount = 'appOpenCount';
  static const _kLastReviewPromptDate = 'lastReviewPromptDate';
  static const _kReviewPromptedForBuild = 'reviewPromptedForBuild';

  final SharedPreferences _prefs;

  String? get themeModeName => _prefs.getString(_kThemeMode);
  Future<void> setThemeModeName(String name) =>
      _prefs.setString(_kThemeMode, name);

  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_kOnboardingSeen, value);

  int get appOpenCount => _prefs.getInt(_kAppOpenCount) ?? 0;
  Future<void> setAppOpenCount(int value) =>
      _prefs.setInt(_kAppOpenCount, value);

  DateTime? get lastReviewPromptDate {
    final iso = _prefs.getString(_kLastReviewPromptDate);
    return iso == null ? null : DateTime.tryParse(iso);
  }
  Future<void> setLastReviewPromptDate(DateTime date) =>
      _prefs.setString(_kLastReviewPromptDate, date.toIso8601String());

  String? get reviewPromptedForBuild =>
      _prefs.getString(_kReviewPromptedForBuild);
  Future<void> setReviewPromptedForBuild(String buildNumber) =>
      _prefs.setString(_kReviewPromptedForBuild, buildNumber);
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/data/preferences_test.dart
```

Expected: all 8 tests pass.

- [ ] **Step 6: Add the Riverpod provider**

Create `lib/providers/preferences_provider.dart`:

```dart
// ABOUTME: Riverpod provider for the Preferences wrapper.
// ABOUTME: Increments appOpenCount once per app process during build.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/preferences.dart';

part 'preferences_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Preferences> preferences(Ref ref) async {
  final raw = await SharedPreferences.getInstance();
  final prefs = Preferences(raw);
  await prefs.setAppOpenCount(prefs.appOpenCount + 1);
  return prefs;
}
```

- [ ] **Step 7: Run codegen**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/providers/preferences_provider.g.dart` is generated, no errors.

- [ ] **Step 8: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/preferences.dart lib/providers/preferences_provider.dart lib/providers/preferences_provider.g.dart test/data/preferences_test.dart
git commit -m "feat: add typed Preferences wrapper around shared_preferences"
```

---

## Task 2: Add Privacy Policy tile

**Files:**
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- Test: `test/screens/o_aplikaciji_screen_test.dart`

- [ ] **Step 1: Write failing test for the Privacy Policy tile**

Append to `test/screens/o_aplikaciji_screen_test.dart` inside the existing `group('action tiles', ...)` block (right after the existing `'renders both action tiles on non-web'` test):

```dart
    testWidgets('renders Privacy Policy tile with button semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Politika privatnosti'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);

      final data = tester
          .getSemantics(find.byIcon(Icons.privacy_tip_outlined))
          .getSemanticsData();
      expect(
        data.label,
        contains('Otvori politiku privatnosti u pregledaču'),
      );
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
      handle.dispose();
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart -p chrome
```

(Or omit `-p chrome` if running on default platform.) Expected: the new test fails with `Expected: exactly one matching candidate ... Actually: _NoElementsFoundError`.

Run without platform flag:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: 1 test fails (the new one), others still pass.

- [ ] **Step 3: Add the Privacy Policy URL constant and tile**

Edit `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`:

After the existing top-level constants at lines 14-20 (`_playStoreUrl`, `_feedbackEmail`, `_feedbackSubject`, `_linkErrorMessage`, `_feedbackErrorMessage`), add:

```dart
const _privacyPolicyUrl = 'https://sites.google.com/view/serbiaopendata/home';
```

(Note: the `_dataSourceUrl` constant near line 340 is unrelated and stays where it is.)

Inside `_OAplikacijiScreenState`, add a new method right after `_openFeedback`:

```dart
  Future<void> _openPrivacyPolicy() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showSnack(_linkErrorMessage);
    } on PlatformException catch (_) {
      if (mounted) _showSnack(_linkErrorMessage);
    }
  }
```

Then in the `build` method, locate the existing feedback `_ActionCard` (line 163-169) and insert a new `_ActionCard` immediately after it (before `const SizedBox(height: 24)` at line 170):

```dart
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Politika privatnosti',
              subtitle: 'Pogledaj kako koristimo podatke',
              semanticsLabel: 'Otvori politiku privatnosti u pregledaču',
              onTap: _openPrivacyPolicy,
            ),
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/o_aplikaciji/o_aplikaciji_screen.dart test/screens/o_aplikaciji_screen_test.dart
git commit -m "feat: add Privacy Policy tile linking to Google Sites page"
```

---

## Task 3: Add `in_app_review` and `ReviewPrompter`

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/data/review_prompter.dart`
- Create: `lib/providers/review_prompter_provider.dart`
- Test: `test/data/review_prompter_test.dart`

- [ ] **Step 1: Add `in_app_review` dependency**

Edit `pubspec.yaml` — under `dependencies:`, add the line directly after `shared_preferences: ^2.3.5`:

```yaml
  in_app_review: ^2.0.10
```

Then run:

```bash
flutter pub get
```

Expected: resolution succeeds. If pub.dev shows a newer stable major-compatible version, prefer that and update the spec note.

- [ ] **Step 2: Write failing tests for `ReviewPrompter` eligibility**

Create `test/data/review_prompter_test.dart`:

```dart
// ABOUTME: Tests for ReviewPrompter eligibility and side effects.
// ABOUTME: Verifies the count/build/date predicates and that maybePrompt is a no-op when ineligible.

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/preferences.dart';
import 'package:rpg_claude/data/review_prompter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReview implements ReviewClient {
  bool available = true;
  int requestCalls = 0;
  Object? throwOnRequest;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestCalls++;
    if (throwOnRequest != null) throw throwOnRequest!;
  }
}

Future<Preferences> _prefsWith(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  return Preferences(await SharedPreferences.getInstance());
}

void main() {
  group('isEligible', () {
    test('false when appOpenCount < 3', () async {
      final prefs = await _prefsWith({'appOpenCount': 2});
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: _FakeReview(),
        now: () => DateTime.utc(2026, 4, 29),
      );
      expect(prompter.isEligible, isFalse);
    });

    test('false when already prompted for current build', () async {
      final prefs = await _prefsWith({
        'appOpenCount': 3,
        'reviewPromptedForBuild': '6',
      });
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: _FakeReview(),
        now: () => DateTime.utc(2026, 4, 29),
      );
      expect(prompter.isEligible, isFalse);
    });

    test('false when last prompt < 30 days ago', () async {
      final prefs = await _prefsWith({
        'appOpenCount': 3,
        'lastReviewPromptDate': DateTime.utc(2026, 4, 10).toIso8601String(),
      });
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: _FakeReview(),
        now: () => DateTime.utc(2026, 4, 29),
      );
      expect(prompter.isEligible, isFalse);
    });

    test('true when count >= 3, no prior build prompt, no recent date', () async {
      final prefs = await _prefsWith({'appOpenCount': 3});
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: _FakeReview(),
        now: () => DateTime.utc(2026, 4, 29),
      );
      expect(prompter.isEligible, isTrue);
    });

    test('true when last prompt was 30 days ago and build differs', () async {
      final prefs = await _prefsWith({
        'appOpenCount': 5,
        'reviewPromptedForBuild': '5',
        'lastReviewPromptDate':
            DateTime.utc(2026, 3, 30).toIso8601String(),
      });
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: _FakeReview(),
        now: () => DateTime.utc(2026, 4, 29),
      );
      expect(prompter.isEligible, isTrue);
    });

    test('false after a session-scoped prompt fired once', () async {
      final prefs = await _prefsWith({'appOpenCount': 3});
      final review = _FakeReview();
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: review,
        now: () => DateTime.utc(2026, 4, 29),
      );
      await prompter.maybePrompt();
      expect(prompter.isEligible, isFalse);
    });
  });

  group('maybePrompt', () {
    test('does not call requestReview when ineligible', () async {
      final prefs = await _prefsWith({'appOpenCount': 1});
      final review = _FakeReview();
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: review,
        now: () => DateTime.utc(2026, 4, 29),
      );
      await prompter.maybePrompt();
      expect(review.requestCalls, 0);
    });

    test('does not call requestReview when isAvailable is false', () async {
      final prefs = await _prefsWith({'appOpenCount': 5});
      final review = _FakeReview()..available = false;
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: review,
        now: () => DateTime.utc(2026, 4, 29),
      );
      await prompter.maybePrompt();
      expect(review.requestCalls, 0);
    });

    test('calls requestReview and persists date + build when eligible', () async {
      final prefs = await _prefsWith({'appOpenCount': 5});
      final review = _FakeReview();
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: review,
        now: () => DateTime.utc(2026, 4, 29),
      );
      await prompter.maybePrompt();
      expect(review.requestCalls, 1);
      expect(prefs.reviewPromptedForBuild, '6');
      expect(prefs.lastReviewPromptDate, DateTime.utc(2026, 4, 29));
    });

    test('swallows platform exceptions and never throws', () async {
      final prefs = await _prefsWith({'appOpenCount': 5});
      final review = _FakeReview()..throwOnRequest = Exception('quota');
      final prompter = ReviewPrompter(
        prefs: prefs,
        currentBuildNumber: '6',
        review: review,
        now: () => DateTime.utc(2026, 4, 29),
      );
      await expectLater(prompter.maybePrompt(), completes);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/data/review_prompter_test.dart
```

Expected: all tests fail with `Target of URI doesn't exist: 'package:rpg_claude/data/review_prompter.dart'`.

- [ ] **Step 4: Implement `ReviewPrompter`**

Create `lib/data/review_prompter.dart`:

```dart
// ABOUTME: Decides when to request a native rating prompt and persists state.
// ABOUTME: Eligibility uses app-open count, current build number, and a 30-day cooldown.

import 'package:in_app_review/in_app_review.dart';
import 'preferences.dart';

abstract interface class ReviewClient {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class _InAppReviewClient implements ReviewClient {
  const _InAppReviewClient();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

class ReviewPrompter {
  ReviewPrompter({
    required Preferences prefs,
    required String currentBuildNumber,
    ReviewClient? review,
    DateTime Function() now = DateTime.now,
  }) : _prefs = prefs,
       _currentBuildNumber = currentBuildNumber,
       _review = review ?? const _InAppReviewClient(),
       _now = now;

  final Preferences _prefs;
  final String _currentBuildNumber;
  final ReviewClient _review;
  final DateTime Function() _now;
  bool _promptedThisSession = false;

  bool get isEligible {
    if (_promptedThisSession) return false;
    if (_prefs.appOpenCount < 3) return false;
    if (_prefs.reviewPromptedForBuild == _currentBuildNumber) return false;
    final last = _prefs.lastReviewPromptDate;
    if (last != null && _now().difference(last).inDays < 30) return false;
    return true;
  }

  Future<void> maybePrompt() async {
    if (!isEligible) return;
    try {
      if (!await _review.isAvailable()) return;
      await _review.requestReview();
      await _prefs.setLastReviewPromptDate(_now());
      await _prefs.setReviewPromptedForBuild(_currentBuildNumber);
      _promptedThisSession = true;
    } on Exception {
      // Platform sheet failures are not actionable for the user.
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/data/review_prompter_test.dart
```

Expected: all 10 tests pass.

- [ ] **Step 6: Add the provider**

Create `lib/providers/review_prompter_provider.dart`:

```dart
// ABOUTME: Riverpod provider for ReviewPrompter; depends on Preferences and PackageInfo.
// ABOUTME: Constructs the prompter once per app process via keepAlive.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/review_prompter.dart';
import 'preferences_provider.dart';

part 'review_prompter_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ReviewPrompter> reviewPrompter(Ref ref) async {
  final prefs = await ref.watch(preferencesProvider.future);
  final info = await PackageInfo.fromPlatform();
  return ReviewPrompter(prefs: prefs, currentBuildNumber: info.buildNumber);
}
```

- [ ] **Step 7: Run codegen**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/providers/review_prompter_provider.g.dart` is generated, no errors.

- [ ] **Step 8: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/review_prompter.dart lib/providers/review_prompter_provider.dart lib/providers/review_prompter_provider.g.dart test/data/review_prompter_test.dart
git commit -m "feat: add ReviewPrompter with eligibility-based throttling"
```

---

## Task 4: Wire `ReviewPrompter` into Mapa and Trendovi screens

**Files:**
- Modify: `lib/screens/mapa/mapa_screen.dart`
- Modify: `lib/screens/trendovi/trendovi_screen.dart`

- [ ] **Step 1: Trigger from MapaScreen post-frame**

Edit `lib/screens/mapa/mapa_screen.dart`. Add this import next to the other relative imports near the top:

```dart
import '../../providers/review_prompter_provider.dart';
```

Add a session-scoped flag in `_MapaScreenState` (right after the existing fields like `_overlayHeight = 0;`):

```dart
  bool _reviewPromptAttempted = false;
```

Inside `build()` (around line 117-118 where `dataAsync` is computed), after `final resolver = ref.watch(...)`, add a post-frame trigger that fires once after the first successful render with non-empty data. The flag mutation lives inside the post-frame callback (not in `build()`) so we never write state during a build pass:

```dart
    if (!_reviewPromptAttempted &&
        dataAsync.hasValue &&
        dataAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_reviewPromptAttempted || !mounted) return;
        _reviewPromptAttempted = true;
        ref
            .read(reviewPrompterProvider.future)
            .then((p) => p.maybePrompt())
            .catchError((Object _) {
          // ReviewPrompter swallows its own platform errors; this catch is a
          // last-resort guard for tests where preferencesProvider /
          // reviewPrompterProvider build fails without explicit overrides.
        });
      });
    }
```

A redundant `addPostFrameCallback` may be scheduled on the rebuild between when the gate first becomes true and when the callback runs; the in-callback `_reviewPromptAttempted` check makes those subsequent callbacks no-op.

- [ ] **Step 2: Trigger from TrendoviScreen post-frame**

Edit `lib/screens/trendovi/trendovi_screen.dart`. Add the import:

```dart
import '../../providers/review_prompter_provider.dart';
```

Add a session-scoped flag in `_TrendoviScreenState` (right after the existing fields like `final Set<AgeBracket> _selectedAgeBrackets = ...`):

```dart
  bool _reviewPromptAttempted = false;
```

In `build()` after `final dataAsync = ref.watch(dataRepositoryProvider);`, add the same post-frame trigger:

```dart
    if (!_reviewPromptAttempted &&
        dataAsync.hasValue &&
        dataAsync.value!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_reviewPromptAttempted || !mounted) return;
        _reviewPromptAttempted = true;
        ref
            .read(reviewPrompterProvider.future)
            .then((p) => p.maybePrompt())
            .catchError((Object _) {
          // See MapaScreen note above.
        });
      });
    }
```

- [ ] **Step 3: Seed `SharedPreferences` and `PackageInfo` in screen tests**

The new post-frame trigger reads `reviewPrompterProvider`, which transitively
calls `SharedPreferences.getInstance()` and `PackageInfo.fromPlatform()`.
Both throw `MissingPluginException` in widget tests unless mocks are
installed. The `.catchError(...)` guard above keeps the future from leaking,
but the cleaner fix is to install plugin mocks in every test file that pumps
`MapaScreen` or `TrendoviScreen`.

Edit `test/screens/mapa_screen_test.dart` and `test/screens/trendovi_screen_test.dart`. At the top of `void main()` (or in an existing top-level `setUp`), add:

```dart
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'GeoAgro Srbija',
      packageName: 'com.serbiaOpenData.rpg_claude',
      version: '1.0.3',
      buildNumber: '6',
      buildSignature: '',
    );
  });
```

Add the imports if not already present:

```dart
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 4: Run analyzer and existing tests**

Run:

```bash
flutter analyze
flutter test test/screens/mapa_screen_test.dart test/screens/trendovi_screen_test.dart
```

Expected: zero analyzer issues; existing screen tests still pass. With the plugin mocks installed in Step 3, the prompter pipeline resolves cleanly without polluting test output.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/mapa/mapa_screen.dart lib/screens/trendovi/trendovi_screen.dart test/screens/mapa_screen_test.dart test/screens/trendovi_screen_test.dart
git commit -m "feat: trigger native rating prompt from Mapa and Trendovi"
```

---

## Task 5: Release boundary 1.0.3+6

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Bump version**

Edit `pubspec.yaml` line 4 from:

```yaml
version: 1.0.2+5
```

to:

```yaml
version: 1.0.3+6
```

- [ ] **Step 2: Run full test suite and analyzer**

Run:

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

Expected: zero analyzer issues, all tests pass, format check exits 0.

- [ ] **Step 3: Manual smoke on Android device (API 30+)**

Build and install:

```bash
flutter build apk --release
flutter install
```

On the device, verify:
- Open app → no onboarding (Feature D not yet shipped).
- O aplikaciji → Privacy Policy tile is present → tap → Google Sites page opens in browser. Visually confirm the page actually contains a privacy policy.
- Force eligibility: clear app data, open three times, then visit Mapa → native rating sheet appears. Re-open → does not appear again same build.
- Manual rate tile from Phase 1 still opens Play Store listing.
- Feedback `mailto:` from Phase 1 still works.

If the Privacy Policy URL points to `/home` and the page does not contain policy text, stop here and confirm with Milan whether to substitute a sub-URL. Otherwise proceed.

- [ ] **Step 4: Commit version bump and tag**

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.3+6"
git tag v1.0.3+6 HEAD
```

- [ ] **Step 5: Push main and tag**

Confirm with Milan before pushing.

```bash
git push origin main
git push origin v1.0.3+6
```

- [ ] **Step 6: Submit Play Console internal track**

Out-of-repo. Upload the AAB built from this commit to Play Console internal track. Paste the Privacy Policy URL into the Main store listing field.

---

## Task 5.5: Cut feature branch for release 2

**Files:** none (git only)

After 1.0.3 is built and uploaded, cut a branch for the dark-mode + onboarding work. Tasks 6–14 run on this branch and PR back into `main` once 1.0.4 has baked on internal track.

> **State at branch-cut:** `main` has already advanced past Release 1. Latest commit on `main` is the riverpod 3.x migration merge (`pubspec.yaml` reads `version: 1.0.3+7`, latest tag `v1.0.3+7`). Pull `main` before branching so the feature branch starts on top of the migration.

- [ ] **Step 1: Create and check out the branch**

```bash
git checkout main
git pull
git checkout -b feature/dark-mode-onboarding
```

Expected: `Switched to a new branch 'feature/dark-mode-onboarding'`.

---

## Task 6: Refactor theme into `buildAppTheme(Brightness)` + chart extension

**Files:**
- Modify: `lib/theme.dart`
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart` (`cardDecoration` callers)
- Modify: `lib/screens/pregled/pregled_screen.dart` (`cardDecoration` callers)
- Modify: `test/theme_test.dart`

- [ ] **Step 1: Write failing tests for `buildAppTheme` and `ChartColors`**

Replace the entire body of `test/theme_test.dart` with:

```dart
// ABOUTME: Tests for the centralised app theme across light and dark brightness.
// ABOUTME: Verifies token values per brightness and ChartColors theme extension.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/theme.dart';

void main() {
  group('buildAppTheme(light)', () {
    final theme = buildAppTheme(Brightness.light);

    test('primary color is olive green', () {
      expect(
        theme.colorScheme.primary.toARGB32(),
        equals(const Color(0xFF5C7A45).toARGB32()),
      );
    });

    test('scaffold background is warm cream', () {
      expect(
        theme.scaffoldBackgroundColor.toARGB32(),
        equals(const Color(0xFFF5F2EC).toARGB32()),
      );
    });

    test('app bar uses primary background with white foreground', () {
      expect(
        theme.appBarTheme.backgroundColor!.toARGB32(),
        equals(const Color(0xFF5C7A45).toARGB32()),
      );
      expect(
        theme.appBarTheme.foregroundColor!.toARGB32(),
        equals(const Color(0xFFFFFFFF).toARGB32()),
      );
    });

    test('card theme has 12px border radius', () {
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      final radius = (shape.borderRadius as BorderRadius).topLeft;
      expect(radius.x, equals(12));
    });

    test('exposes ChartColors with primary line color', () {
      final chart = theme.extension<ChartColors>();
      expect(chart, isNotNull);
      expect(
        chart!.line.toARGB32(),
        equals(const Color(0xFF5C7A45).toARGB32()),
      );
    });
  });

  group('buildAppTheme(dark)', () {
    final theme = buildAppTheme(Brightness.dark);

    test('scaffold background is dark surface', () {
      expect(
        theme.scaffoldBackgroundColor.toARGB32(),
        equals(const Color(0xFF121417).toARGB32()),
      );
    });

    test('surface uses dark surface token', () {
      expect(
        theme.colorScheme.surface.toARGB32(),
        equals(const Color(0xFF1C1F23).toARGB32()),
      );
    });

    test('primary uses lighter olive token', () {
      expect(
        theme.colorScheme.primary.toARGB32(),
        equals(const Color(0xFF7DA163).toARGB32()),
      );
    });

    test('on-surface uses light text token', () {
      expect(
        theme.colorScheme.onSurface.toARGB32(),
        equals(const Color(0xFFECEAE3).toARGB32()),
      );
    });

    test('app bar uses dark surface background with primary foreground', () {
      expect(
        theme.appBarTheme.backgroundColor!.toARGB32(),
        equals(const Color(0xFF1C1F23).toARGB32()),
      );
      expect(
        theme.appBarTheme.foregroundColor!.toARGB32(),
        equals(const Color(0xFF7DA163).toARGB32()),
      );
    });

    test('exposes ChartColors with dark primary line color', () {
      final chart = theme.extension<ChartColors>();
      expect(chart, isNotNull);
      expect(
        chart!.line.toARGB32(),
        equals(const Color(0xFF7DA163).toARGB32()),
      );
    });
  });

  group('context.cardDecoration', () {
    testWidgets('light: white surface with subtle shadow', (tester) async {
      late BoxDecoration decoration;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Builder(
            builder: (context) {
              decoration = context.cardDecoration;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(decoration.color, equals(const Color(0xFFFFFFFF)));
      expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
      expect(decoration.boxShadow, hasLength(1));
      final shadow = decoration.boxShadow!.single;
      expect(shadow.color, equals(const Color(0x0F000000)));
      expect(shadow.blurRadius, equals(8));
      expect(shadow.offset, equals(const Offset(0, 2)));
    });

    testWidgets('dark: dark surface with stronger shadow', (tester) async {
      late BoxDecoration decoration;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: Builder(
            builder: (context) {
              decoration = context.cardDecoration;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(decoration.color, equals(const Color(0xFF1C1F23)));
      expect(decoration.boxShadow!.single.color, equals(const Color(0x1F000000)));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/theme_test.dart
```

Expected: tests fail with `The function 'buildAppTheme' isn't defined` and similar errors for `ChartColors` and `context.cardDecoration`.

- [ ] **Step 3: Rewrite `lib/theme.dart`**

Replace the entire body of `lib/theme.dart` with:

```dart
// ABOUTME: Centralised app theme — defines all visual tokens for light and dark.
// ABOUTME: Screens read tokens from Theme.of(context) and context.cardDecoration.

import 'package:flutter/material.dart';

const _primary = Color(0xFF5C7A45);
const _background = Color(0xFFF5F2EC);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B6B6B);

const _backgroundDark = Color(0xFF121417);
const _surfaceDark = Color(0xFF1C1F23);
const _primaryDark = Color(0xFF7DA163);
const _textPrimaryDark = Color(0xFFECEAE3);
const _textSecondaryDark = Color(0xFFA0A0A0);

/// Amber accent for secondary highlights (chart accents, badges).
const accentColor = Color(0xFFC47B2B);

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? _primaryDark : _primary;
  final background = isDark ? _backgroundDark : _background;
  final surface = isDark ? _surfaceDark : _surface;
  final textPrimary = isDark ? _textPrimaryDark : _textPrimary;
  final textSecondary = isDark ? _textSecondaryDark : _textSecondary;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: brightness,
    primary: primary,
    surface: surface,
    onSurface: textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? surface : primary,
      foregroundColor: isDark ? primary : Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: surface,
      shadowColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: textSecondary),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: background,
      selectedColor: primary,
      labelStyle: TextStyle(color: textPrimary),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      showCheckmark: true,
      checkmarkColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary),
      ),
    ),
    textTheme: TextTheme(
      headlineSmall:
          TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
      titleMedium:
          TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
      bodyMedium:
          TextStyle(fontWeight: FontWeight.w400, color: textPrimary),
      bodySmall:
          TextStyle(fontWeight: FontWeight.w500, color: textSecondary),
    ),
    extensions: [ChartColors.from(brightness)],
  );
}

@immutable
class ChartColors extends ThemeExtension<ChartColors> {
  const ChartColors({required this.line, required this.fill});

  final Color line;
  final Color fill;

  factory ChartColors.from(Brightness brightness) =>
      brightness == Brightness.dark
      ? const ChartColors(line: _primaryDark, fill: _primaryDark)
      : const ChartColors(line: _primary, fill: _primary);

  @override
  ChartColors copyWith({Color? line, Color? fill}) =>
      ChartColors(line: line ?? this.line, fill: fill ?? this.fill);

  @override
  ChartColors lerp(ThemeExtension<ChartColors>? other, double t) {
    if (other is! ChartColors) return this;
    return ChartColors(
      line: Color.lerp(line, other.line, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
    );
  }
}

extension AppDecorations on BuildContext {
  /// Card-like container decoration with shadow that adapts to brightness.
  BoxDecoration get cardDecoration {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x1F000000) : const Color(0x0F000000),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Update all `cardDecoration` call sites**

Run a grep to confirm the list of callers:

```bash
grep -rn "cardDecoration" lib/
```

For each non-`theme.dart` site, replace `decoration: cardDecoration,` with `decoration: context.cardDecoration,`. The current callers are:
- `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart:242` — inside `_InfoCard.build` which already has `context`. Change to `context.cardDecoration`.
- `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart:293` — inside `_ActionCard.build` with `context`. Change to `context.cardDecoration`.
- `lib/screens/pregled/pregled_screen.dart:219`, `:337`, `:732`, `:775` — all inside builder methods with a `context` in scope. Change each to `context.cardDecoration`.

If the grep reveals additional sites, change them too.

- [ ] **Step 5: Replace `appTheme` test references**

The old `appTheme` constant is gone. Confirm the affected files via grep:

```bash
grep -rn "appTheme" test/
```

Three files need editing (the fourth, `test/theme_test.dart`, is already handled by Step 1's full rewrite):

- `test/navigation/shell_test.dart` — 5 occurrences of `theme: appTheme`.
- `test/screens/mapa_screen_test.dart` — 9 occurrences of `theme: appTheme`.
- `test/screens/o_aplikaciji_screen_test.dart` — 6 occurrences of `theme: appTheme`.

In each file, replace `theme: appTheme` with `theme: buildAppTheme(Brightness.light)`. The existing `import 'package:rpg_claude/theme.dart';` line stays — `buildAppTheme` is exported from the same file.

If grep surfaces additional files beyond these three, edit them the same way.

- [ ] **Step 6: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues. If a `cardDecoration` reference is undefined in a function without `context`, the analyzer will surface it — fix by threading `context` through that helper.

- [ ] **Step 7: Run all existing tests**

Run:

```bash
flutter test
```

Expected: all tests pass. (Existing screen tests should be unaffected; theme tests now exercise both brightnesses.)

- [ ] **Step 8: Commit**

```bash
git add lib/theme.dart lib/screens/ test/
git commit -m "refactor: convert theme to buildAppTheme(Brightness) + cardDecoration extension"
```

---

## Task 7: Add `themeModeProvider` and wire into `MaterialApp`

**Files:**
- Create: `lib/providers/theme_mode_provider.dart`
- Modify: `lib/app.dart`
- Test: `test/providers/theme_mode_provider_test.dart`

- [ ] **Step 1: Write failing tests for `themeModeProvider`**

Create `test/providers/theme_mode_provider_test.dart`:

```dart
// ABOUTME: Tests for the themeModeProvider read/write through Preferences.
// ABOUTME: Verifies initial value loading and propagation of state changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/preferences.dart';
import 'package:rpg_claude/providers/preferences_provider.dart';
import 'package:rpg_claude/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Preferences> _seedPrefs(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  return Preferences(await SharedPreferences.getInstance());
}

void main() {
  test('defaults to ThemeMode.system when prefs unset', () async {
    final prefs = await _seedPrefs({});
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWith((_) async => prefs)],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    expect(container.read(themeModeNotifierProvider), ThemeMode.system);
  });

  test('reads stored ThemeMode.dark from prefs', () async {
    final prefs = await _seedPrefs({'themeMode': 'dark'});
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWith((_) async => prefs)],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
  });

  test('setMode writes through to prefs and updates state', () async {
    final prefs = await _seedPrefs({});
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWith((_) async => prefs)],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);

    await container
        .read(themeModeNotifierProvider.notifier)
        .setMode(ThemeMode.dark);

    expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
    expect(prefs.themeModeName, 'dark');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/providers/theme_mode_provider_test.dart
```

Expected: tests fail with `Target of URI doesn't exist: 'package:rpg_claude/providers/theme_mode_provider.dart'`.

- [ ] **Step 3: Implement `themeModeProvider`**

Create `lib/providers/theme_mode_provider.dart`:

```dart
// ABOUTME: Riverpod notifier for ThemeMode backed by Preferences.
// ABOUTME: Loads initial mode from prefs and persists changes through setMode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'preferences_provider.dart';

part 'theme_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final prefs = ref.watch(preferencesProvider).valueOrNull;
    return _toThemeMode(prefs?.themeModeName);
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = ref.read(preferencesProvider).valueOrNull;
    if (prefs == null) return;
    await prefs.setThemeModeName(mode.name);
    state = mode;
  }
}

ThemeMode _toThemeMode(String? name) => switch (name) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};
```

> **UX note (one-frame flash):** While `preferencesProvider` is still loading on cold start, `valueOrNull` is null and the notifier returns `ThemeMode.system`. A user who selected dark will see a single frame of light theme before the notifier rebuilds with the persisted value. The `LoadingScreen` route is shown immediately after, so the flash is bounded to the very first frame. Acceptable for v1 — if a fix becomes desirable, gate `MaterialApp.router` on `ref.watch(preferencesProvider)` resolving and show a brightness-neutral splash until then.

- [ ] **Step 4: Run codegen**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/providers/theme_mode_provider.g.dart` is generated.

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/providers/theme_mode_provider_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 6: Wire `themeMode` into `MaterialApp.router`**

Replace the entire body of `lib/app.dart` with:

```dart
// ABOUTME: Root widget — configures MaterialApp with GoRouter, themes, and themeMode.
// ABOUTME: Watches the router, theme, and themeMode providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/router.dart';
import 'providers/theme_mode_provider.dart';
import 'theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeNotifierProvider);
    return MaterialApp.router(
      title: 'GeoAgro Srbija',
      routerConfig: router,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: mode,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 7: Run analyzer and full tests**

Run:

```bash
flutter analyze
flutter test
```

Expected: zero analyzer issues, all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/providers/theme_mode_provider.dart lib/providers/theme_mode_provider.g.dart lib/app.dart test/providers/theme_mode_provider_test.dart
git commit -m "feat: add themeModeProvider and wire into MaterialApp"
```

---

## Task 8: Add `SegmentedButton` theme toggle in O aplikaciji

**Files:**
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- Test: `test/screens/o_aplikaciji_screen_test.dart`

- [ ] **Step 1: Write failing test for the toggle**

Append a new group at the end of `test/screens/o_aplikaciji_screen_test.dart` (before the trailing helper class definitions):

```dart
  group('theme mode toggle', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'GeoAgro Srbija',
        packageName: 'com.serbiaOpenData.rpg_claude',
        version: '1.0.4',
        buildNumber: '9',
        buildSignature: '',
      );
    });

    testWidgets('renders three segments with Sistem selected by default', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: const OAplikacijiScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Svetla'), findsOneWidget);
      expect(find.text('Tamna'), findsOneWidget);
    });

    testWidgets('tapping Tamna writes ThemeMode.dark to prefs', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: const OAplikacijiScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tamna'));
      await tester.pumpAndSettle();

      final raw = await SharedPreferences.getInstance();
      expect(raw.getString('themeMode'), 'dark');
    });
  });
```

Add these imports at the top of the test file (alongside the existing imports):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: the two new tests fail with `Expected: exactly one matching candidate ... Actually: _NoElementsFoundError`.

- [ ] **Step 3: Wrap existing tests with `ProviderScope`**

`OAplikacijiScreen` will become a `ConsumerStatefulWidget` in step 4. Every existing `pumpWidget` call in `test/screens/o_aplikaciji_screen_test.dart` must be wrapped with `ProviderScope` first or the test will throw `No ProviderScope found` when it pumps.

For each occurrence in the file, change patterns like:

```dart
await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
```

to:

```dart
await tester.pumpWidget(
  const ProviderScope(child: MaterialApp(home: OAplikacijiScreen())),
);
```

And:

```dart
await tester.pumpWidget(
  MaterialApp(theme: buildAppTheme(Brightness.light), home: const OAplikacijiScreen()),
);
```

to:

```dart
await tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: const OAplikacijiScreen(),
    ),
  ),
);
```

Each wrapped test will need `SharedPreferences.setMockInitialValues({})` in its setUp (or test body) so `preferencesProvider` resolves cleanly. Tests that already have a setUp can extend it; tests without one can add a one-line call before the pumpWidget.

Run the existing tests after this edit to confirm they still pass:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: all pre-existing tests pass.

- [ ] **Step 4: Add the SegmentedButton above the action cards**

Edit `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`:

- Add imports near the top:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_mode_provider.dart';
```

- Change the class signature from `StatefulWidget` to a `ConsumerStatefulWidget` and the State to `ConsumerState`:

```dart
class OAplikacijiScreen extends ConsumerStatefulWidget {
  const OAplikacijiScreen({super.key});

  @override
  ConsumerState<OAplikacijiScreen> createState() => _OAplikacijiScreenState();
}

class _OAplikacijiScreenState extends ConsumerState<OAplikacijiScreen> {
```

- In the `build` method, locate the `const SizedBox(height: 24)` that sits before the `if (showRate) ...` block (around line 152) and insert this directly above it:

```dart
            _ThemeModeToggle(
              current: ref.watch(themeModeNotifierProvider),
              onChanged: (mode) =>
                  ref.read(themeModeNotifierProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: 24),
```

- Add the toggle widget at the bottom of the file (after `_TabGuide`):

```dart
class _ThemeModeToggle extends StatelessWidget {
  const _ThemeModeToggle({required this.current, required this.onChanged});

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
        ButtonSegment(value: ThemeMode.light, label: Text('Svetla')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Tamna')),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/o_aplikaciji/o_aplikaciji_screen.dart test/screens/o_aplikaciji_screen_test.dart
git commit -m "feat: add theme mode SegmentedButton in O aplikaciji"
```

---

## Task 9: Dark palette audit and golden tests

**Files:**
- Modify: `lib/screens/mapa/mapa_screen.dart`
- Modify: `lib/screens/trendovi/trendovi_screen.dart`
- Modify: `lib/screens/pregled/pregled_screen.dart`
- Modify: `lib/screens/opstine/opstina_detail_screen.dart`
- Modify: `lib/screens/loading/loading_screen.dart`
- Create: `test/golden/o_aplikaciji_dark_test.dart`
- Create: `test/golden/pregled_dark_test.dart`
- Create: `test/golden/trendovi_dark_test.dart`

- [ ] **Step 1: Audit hardcoded colors**

Run:

```bash
grep -rn "Colors\.\|Color(0x" lib/screens/ lib/widgets/ lib/layout/
```

For each match, decide:
- If the color expresses a semantic role (text, surface, primary), replace it with the corresponding `Theme.of(context).colorScheme.X` token.
- If it's a chart color, replace it with `Theme.of(context).extension<ChartColors>()!.line` or `.fill`.
- If it's a metric-specific decorative color (e.g., `Colors.green.shade100` for the Mapa metric legend), keep it but verify visibly that contrast against `_surfaceDark` is acceptable. Document the decision inline only if behavior is non-obvious — otherwise leave no comment.
- `Colors.white` and `Colors.transparent` may be left where they are intentional (e.g., chip checkmark, ink splash backdrop).

Specific known sites to fix:

**Chart tooltip TEXT (`Colors.black87`) — KEEP black, do not theme-swap.** The chart tooltip BACKGROUND at `trendovi_screen.dart:335`, `pregled_screen.dart:390`, and `opstina_detail_screen.dart` (search for `getTooltipColor`) is hardcoded to `Color.fromARGB(255, 237, 191, 136)` (light beige) in both modes. Replacing the foreground with `colorScheme.onSurface` would render light-on-light text in dark mode → tooltip becomes unreadable. Until the tooltip background is themed too, leave these black:
- `lib/screens/trendovi/trendovi_screen.dart:343` — line-chart tooltip text. **Leave as `Colors.black87`.**
- `lib/screens/opstine/opstina_detail_screen.dart:131,330,486` — same pattern. **Leave as `Colors.black87`.**
- `lib/screens/pregled/pregled_screen.dart:399,529` — same pattern. **Leave as `Colors.black87`.**

If a future task themes the tooltip BG, revisit these together — for now keep them paired.

**Other sites:**
- `lib/screens/mapa/mapa_screen.dart:693` — `color: Color(0x29000000)` shadow on overlay → replace with a brightness-aware shadow. Use `Theme.of(context).brightness == Brightness.dark ? const Color(0x40000000) : const Color(0x29000000)`.
- `lib/screens/mapa/mapa_screen.dart:709` — `Colors.grey.shade300` placeholder → replace with `Theme.of(context).colorScheme.surfaceContainerHighest` (or `surface` darker variant if the analyzer disagrees).
- `lib/screens/loading/loading_screen.dart` — already reads `colorScheme.error`. No change needed; verify visually.

The Mapa choropleth swatches at `mapa_screen.dart:452-462,482,491,500` represent metric-specific data and render over the OSM tile (which stays light in both modes per Step 8); they should stay. Visually confirm during Step 8 that swatches remain distinguishable from each other.

The trendovi `selectedColor: Theme.of(context).colorScheme.primary` (line 63) and the `Colors.white` chip label in dark mode looks fine — leave it.

- [ ] **Step 2: Run analyzer and full tests**

Run:

```bash
flutter analyze
flutter test
```

Expected: zero issues, all tests pass.

- [ ] **Step 3: Write golden test for `OAplikacijiScreen` (dark)**

Create `test/golden/o_aplikaciji_dark_test.dart`:

```dart
// ABOUTME: Golden test for the O aplikaciji screen in dark mode.
// ABOUTME: Catches regressions in dark palette tokens for static content.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rpg_claude/screens/o_aplikaciji/o_aplikaciji_screen.dart';
import 'package:rpg_claude/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('OAplikacijiScreen dark golden', (tester) async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    PackageInfo.setMockInitialValues(
      appName: 'GeoAgro Srbija',
      packageName: 'com.serbiaOpenData.rpg_claude',
      version: '1.0.4',
      buildNumber: '9',
      buildSignature: '',
    );
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: const OAplikacijiScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OAplikacijiScreen),
      matchesGoldenFile('goldens/o_aplikaciji_dark.png'),
    );
  });
}
```

- [ ] **Step 4: Generate the golden**

Run:

```bash
flutter test --update-goldens test/golden/o_aplikaciji_dark_test.dart
```

Expected: `test/golden/goldens/o_aplikaciji_dark.png` is created.

- [ ] **Step 5: Verify golden test runs green without `--update-goldens`**

Run:

```bash
flutter test test/golden/o_aplikaciji_dark_test.dart
```

Expected: test passes.

- [ ] **Step 6: Write golden test for `PregledScreen` (dark)**

The existing `test/screens/pregled_screen_test.dart` (around line 383) defines `_FixtureRepository extends DataRepository` plus `_FixtureFarmSizeRepository` and `_FixtureAgeRepository`. The golden test must mirror that setup or `PregledScreen` will render its loading/error state instead of the chart-bearing surface we want to capture.

Create `test/golden/pregled_dark_test.dart` by copying the fixture classes (the `_FixtureRepository`, `_FixtureFarmSizeRepository`, `_FixtureAgeRepository`, `_resolver`, and the seed `Snapshot` data) verbatim from `test/screens/pregled_screen_test.dart`, and use them in a `ProviderScope` keyed to the dark theme:

```dart
// ABOUTME: Golden test for the Pregled screen in dark mode.
// ABOUTME: Reuses the fixture repositories from pregled_screen_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/providers/age_provider.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/providers/farm_size_provider.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/screens/pregled/pregled_screen.dart';
import 'package:rpg_claude/theme.dart';

// Copy _FixtureRepository, _FixtureFarmSizeRepository, _FixtureAgeRepository,
// the _resolver constant, and any seed Snapshot data from
// test/screens/pregled_screen_test.dart verbatim into this file.

void main() {
  testWidgets('PregledScreen dark golden', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FixtureRepository()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
          farmSizeRepositoryProvider
              .overrideWith(() => _FixtureFarmSizeRepository()),
          ageRepositoryProvider.overrideWith(() => _FixtureAgeRepository()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: const Scaffold(body: PregledScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PregledScreen),
      matchesGoldenFile('goldens/pregled_dark.png'),
    );
  });
}
```

Before running, open `test/screens/pregled_screen_test.dart` and copy the following blocks verbatim into `test/golden/pregled_dark_test.dart`:
- Lines 22-138: the `_rec()` helper, `_snapshot1`, `_snapshot2`, `_fixtureSnapshots`, `_farmSizeSnapshot`, `_ageSnapshot`, and `_resolver` constants (the entire seed-data block).
- Lines 383-386: `_FixtureRepository`.
- Lines 393-396: `_FixtureFarmSizeRepository`.
- Lines 398-401: `_FixtureAgeRepository`.

You do NOT need `_SingleSnapshotRepository`, `_ErrorFarmSizeRepository`, or `_ErrorAgeRepository` — only the three fixtures referenced by the golden test's overrides. The override pattern `dataRepositoryProvider.overrideWith(() => _FixtureRepository())` is the AsyncNotifier override — the existing test uses exactly this shape.

- [ ] **Step 7: Generate the second golden and run**

Run:

```bash
flutter test --update-goldens test/golden/pregled_dark_test.dart
flutter test test/golden/pregled_dark_test.dart
```

Expected: golden created, then test passes.

- [ ] **Step 8: Write golden test for `TrendoviScreen` (dark)**

Trendovi is the chart-heaviest screen in the app and the place where dark-mode chart-color regressions would land — line color, axis label tokens, chip selected/unselected styling, and the deliberate `Colors.black87` tooltip-foreground decision from Step 1. A golden here pairs with the Pregled golden to give chart palette regressions an automatic regression net.

Mirror the existing `test/screens/trendovi_screen_test.dart` fixture setup. Open that file and copy whatever provider overrides and seed data it uses to render the chart (at minimum `dataRepositoryProvider` and `nameResolverProvider`; copy any others the screen reads from). The Pregled golden's verbatim-copy approach in Step 6 is the same pattern — duplicate the fixtures rather than reaching into the screen test file from the golden test.

Create `test/golden/trendovi_dark_test.dart`:

```dart
// ABOUTME: Golden test for the Trendovi screen in dark mode.
// ABOUTME: Catches regressions in chart line color, axis labels, and chip styling.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/trendovi/trendovi_screen.dart';
import 'package:rpg_claude/theme.dart';

// Copy fixture repositories, the _resolver constant, and any seed Snapshot
// data verbatim from test/screens/trendovi_screen_test.dart. Use the same
// override shape (AsyncNotifier overrideWith for repos) the existing tests
// use — do not invent a new override pattern here.

void main() {
  testWidgets('TrendoviScreen dark golden', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Mirror the overrides used in trendovi_screen_test.dart so the
          // chart renders with seed data instead of its loading state.
        ],
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: const Scaffold(body: TrendoviScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TrendoviScreen),
      matchesGoldenFile('goldens/trendovi_dark.png'),
    );
  });
}
```

If `trendovi_screen_test.dart` doesn't already seed data thick enough to drive the chart (a single snapshot is typically not enough for a line chart — Trendovi needs at least two data points), extend the seed locally in the golden test rather than mutating the existing screen test.

- [ ] **Step 9: Generate the third golden and run**

Run:

```bash
flutter test --update-goldens test/golden/trendovi_dark_test.dart
flutter test test/golden/trendovi_dark_test.dart
```

Expected: `test/golden/goldens/trendovi_dark.png` is created, then the test passes without `--update-goldens`. If the chart renders an empty state instead of a line, revisit the seed data — the screen needs at least two snapshots with overlapping municipalities to draw a line.

- [ ] **Step 10: Manual visual smoke (light + dark)**

Build and install:

```bash
flutter build apk --debug
flutter install
```

In each brightness (toggle via Sistem → Svetla and Sistem → Tamna), step through every screen and confirm:
- No invisible text (light text on light surface, etc.).
- Charts (Pregled, Trendovi, Opštine detail) show the chart line clearly.
- Mapa overlay text is readable.
- Filter chip labels readable in selected and unselected states.
- App bars are visually distinct from scaffold body.

Note: OSM tiles render in light style in both modes. Acceptable for now per the spec.

- [ ] **Step 11: Run analyzer and full test suite**

Run:

```bash
flutter analyze
flutter test
```

Expected: zero issues, all tests pass.

- [ ] **Step 12: Commit**

```bash
git add lib/screens/ test/golden/
git commit -m "feat: dark palette audit + golden tests for three key screens"
```

---

## Task 10: Extract onboarding copy

**Files:**
- Create: `lib/data/onboarding_copy.dart`

- [ ] **Step 1: Create the copy file**

Create `lib/data/onboarding_copy.dart`:

```dart
// ABOUTME: Single source of truth for onboarding card copy and icons.
// ABOUTME: Consumed by the onboarding flow.

import 'package:flutter/material.dart';

class OnboardingCard {
  const OnboardingCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const onboardingCards = <OnboardingCard>[
  OnboardingCard(
    icon: Icons.agriculture_outlined,
    title: 'Dobrodošli',
    body:
        'GeoAgro Srbija prikazuje otvorene podatke o registrovanim '
        'poljoprivrednim gazdinstvima u Srbiji. Aplikacija je razvio '
        'nezavisan developer i nije povezana sa državnim organima — '
        'podaci potiču direktno sa portala data.gov.rs i koriste se u '
        'informativne i obrazovne svrhe.',
  ),
  OnboardingCard(
    icon: Icons.dashboard_outlined,
    title: 'Pregled',
    body:
        'Prikazuje ukupan broj registrovanih i aktivnih gazdinstava '
        'na nivou Srbije za najnoviji dostupni snimak podataka, kao i '
        'raspodelu po obliku organizacije.',
  ),
  OnboardingCard(
    icon: Icons.list_alt_outlined,
    title: 'Opštine',
    body:
        'Pretraži sve opštine i pogledaj detalje za svaku — '
        'aktivan broj gazdinstava po obliku organizacije i trend kroz vreme.',
  ),
  OnboardingCard(
    icon: Icons.show_chart_outlined,
    title: 'Trendovi',
    body:
        'Prati kako se broj aktivnih gazdinstava menjao od 2018. '
        'do danas. Filtriraj po opštini i obliku organizacije, ili '
        'poređaj više opština na istom grafikonu.',
  ),
  OnboardingCard(
    icon: Icons.map_outlined,
    title: 'Mapa',
    body:
        'Geografski prikaz Srbije — opštine su obojene prema broju '
        'aktivnih gazdinstava. Dodirnite opštinu za kratki pregled.',
  ),
];
```

- [ ] **Step 2: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 3: Commit**

```bash
git add lib/data/onboarding_copy.dart
git commit -m "refactor: extract onboarding copy into single source of truth"
```

---

## Task 11: Build `OnboardingScreen` and `OnboardingCardView`

**Files:**
- Create: `lib/screens/onboarding/onboarding_card.dart`
- Create: `lib/screens/onboarding/onboarding_screen.dart`
- Test: `test/screens/onboarding_screen_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/screens/onboarding_screen_test.dart`:

```dart
// ABOUTME: Widget tests for the onboarding flow.
// ABOUTME: Verifies cards render, page indicator, skip, and finish behaviour.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rpg_claude/data/preferences.dart';
import 'package:rpg_claude/providers/preferences_provider.dart';
import 'package:rpg_claude/screens/onboarding/onboarding_screen.dart';
import 'package:rpg_claude/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _harness({required Preferences prefs}) async {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/pregled',
        builder: (context, state) => const Scaffold(body: Text('PREGLED')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [preferencesProvider.overrideWith((_) async => prefs)],
    child: MaterialApp.router(
      theme: buildAppTheme(Brightness.light),
      routerConfig: router,
    ),
  );
}

Future<Preferences> _seedPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return Preferences(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('renders the first card on first frame', (tester) async {
    final prefs = await _seedPrefs();
    await tester.pumpWidget(await _harness(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Dobrodošli'), findsOneWidget);
    expect(find.text('Sledeće'), findsOneWidget);
    expect(find.text('Preskoči'), findsOneWidget);
  });

  testWidgets('Sledeće advances pages and shows Završi on the last', (
    tester,
  ) async {
    final prefs = await _seedPrefs();
    await tester.pumpWidget(await _harness(prefs: prefs));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Sledeće'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Završi'), findsOneWidget);
    expect(find.text('Preskoči'), findsNothing);
  });

  testWidgets('Završi sets onboardingSeen and navigates to /pregled', (
    tester,
  ) async {
    final prefs = await _seedPrefs();
    await tester.pumpWidget(await _harness(prefs: prefs));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Sledeće'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Završi'));
    await tester.pumpAndSettle();

    expect(prefs.onboardingSeen, isTrue);
    expect(find.text('PREGLED'), findsOneWidget);
  });

  testWidgets('Preskoči sets onboardingSeen and navigates to /pregled', (
    tester,
  ) async {
    final prefs = await _seedPrefs();
    await tester.pumpWidget(await _harness(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preskoči'));
    await tester.pumpAndSettle();

    expect(prefs.onboardingSeen, isTrue);
    expect(find.text('PREGLED'), findsOneWidget);
  });

  testWidgets('exposes 5 page indicator dots with semantic labels', (
    tester,
  ) async {
    final prefs = await _seedPrefs();
    await tester.pumpWidget(await _harness(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Korak 1 od 5'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: tests fail with `Target of URI doesn't exist: 'package:rpg_claude/screens/onboarding/onboarding_screen.dart'`.

- [ ] **Step 3: Implement the card view**

Create `lib/screens/onboarding/onboarding_card.dart`:

```dart
// ABOUTME: Single onboarding card widget — icon, heading, body, full-screen layout.
// ABOUTME: Pure presentation; navigation and state owned by OnboardingScreen.

import 'package:flutter/material.dart';
import '../../data/onboarding_copy.dart';

class OnboardingCardView extends StatelessWidget {
  const OnboardingCardView({super.key, required this.card});

  final OnboardingCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(card.icon, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Semantics(
            header: true,
            label: card.title,
            child: Text(
              card.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(card.body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement the screen**

Create `lib/screens/onboarding/onboarding_screen.dart`:

```dart
// ABOUTME: Onboarding flow — 5-card PageView with Skip/Next/Finish actions.
// ABOUTME: Persists onboardingSeen via Preferences and navigates to /pregled.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/onboarding_copy.dart';
import '../../providers/preferences_provider.dart';
import 'onboarding_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == onboardingCards.length - 1;

  Future<void> _markSeenAndGo() async {
    final prefs = await ref.read(preferencesProvider.future);
    await prefs.setOnboardingSeen(true);
    if (!mounted) return;
    context.go('/pregled');
  }

  Future<void> _next() async {
    if (_isLast) {
      await _markSeenAndGo();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                // Reserve a fixed-height slot so layout doesn't shift when
                // the button vanishes on the last page. The Text widget must
                // be removed (not just faded with AnimatedOpacity) — fading
                // leaves it discoverable to find.text in tests and to
                // semantic traversal at runtime.
                child: SizedBox(
                  height: kMinInteractiveDimension,
                  child: _isLast
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: _markSeenAndGo,
                          child: const Text('Preskoči'),
                        ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: onboardingCards.length,
                itemBuilder: (_, i) =>
                    OnboardingCardView(card: onboardingCards[i]),
              ),
            ),
            _PageDots(count: onboardingCards.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Završi' : 'Sledeće'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dim = primary.withValues(alpha: 0.25);
    return Semantics(
      label: 'Korak ${index + 1} od $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: i == index ? 24 : 8,
              decoration: BoxDecoration(
                color: i == index ? primary : dim,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/screens/onboarding_screen_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 6: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/onboarding/ test/screens/onboarding_screen_test.dart
git commit -m "feat: add 5-card onboarding flow"
```

---

## Task 12: Wire `/onboarding` route and redirect

**Files:**
- Modify: `lib/navigation/router.dart`
- Test: `test/navigation/onboarding_redirect_test.dart`

- [ ] **Step 1: Write failing tests for the redirect matrix**

Create `test/navigation/onboarding_redirect_test.dart`:

```dart
// ABOUTME: Tests the GoRouter redirect logic for first-launch onboarding.
// ABOUTME: Covers all combinations of (hasData, onboardingSeen, current location).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/preferences.dart';
import 'package:rpg_claude/navigation/router.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Preferences> _seedPrefs(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  return Preferences(await SharedPreferences.getInstance());
}

class _PendingDataRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() => Completer<List<Snapshot>>().future;
}

class _LoadedDataRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [
    Snapshot(date: DateTime.utc(2026, 1, 1), records: const []),
  ];
}

void main() {
  testWidgets('no data: navigating to /pregled redirects back to /ucitavanje', (
    tester,
  ) async {
    final prefs = await _seedPrefs({});
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((_) async => prefs),
        dataRepositoryProvider.overrideWith(() => _PendingDataRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);

    final router = container.read(routerProvider);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    // Sanity: starts on the loading route per initialLocation.
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/ucitavanje',
    );

    // Actually exercise the redirect: try to leave loading while data is
    // still pending.
    router.go('/pregled');
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/ucitavanje',
    );
  });

  testWidgets('data + onboarding unseen -> /ucitavanje routes to /onboarding', (
    tester,
  ) async {
    final prefs = await _seedPrefs({});
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((_) async => prefs),
        dataRepositoryProvider.overrideWith(() => _LoadedDataRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    await container.read(dataRepositoryProvider.future);

    final router = container.read(routerProvider);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/onboarding',
    );
  });

  testWidgets('data + onboarding seen -> /ucitavanje routes to /pregled', (
    tester,
  ) async {
    final prefs = await _seedPrefs({'onboardingSeen': true});
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((_) async => prefs),
        dataRepositoryProvider.overrideWith(() => _LoadedDataRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    await container.read(dataRepositoryProvider.future);

    final router = container.read(routerProvider);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/pregled',
    );
  });

  testWidgets('navigating directly to /onboarding is allowed even when seen', (
    tester,
  ) async {
    final prefs = await _seedPrefs({'onboardingSeen': true});
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((_) async => prefs),
        dataRepositoryProvider.overrideWith(() => _LoadedDataRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    await container.read(dataRepositoryProvider.future);

    final router = container.read(routerProvider);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/onboarding');
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/onboarding',
    );
  });

  testWidgets('data loaded but prefs pending: stays on /ucitavanje', (
    tester,
  ) async {
    // Race-condition guard: if dataRepository resolves before
    // preferencesProvider, the redirect must hold at /ucitavanje rather than
    // dispatching past onboarding for a first-time user.
    final prefsCompleter = Completer<Preferences>();
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((_) => prefsCompleter.future),
        dataRepositoryProvider.overrideWith(() => _LoadedDataRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(dataRepositoryProvider.future);

    final router = container.read(routerProvider);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/ucitavanje',
    );

    // Resolve prefs with onboardingSeen=false; redirect should now fire.
    SharedPreferences.setMockInitialValues({});
    final prefs = Preferences(await SharedPreferences.getInstance());
    prefsCompleter.complete(prefs);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/onboarding',
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/navigation/onboarding_redirect_test.dart
```

Expected: all 5 tests fail (the second and third with the `/pregled` outcome that the current router produces, instead of `/onboarding`; the fourth because the route doesn't exist; the fifth because there is no race-aware gate yet).

- [ ] **Step 3: Update the router**

Edit `lib/navigation/router.dart`. Replace the entire body with:

```dart
// ABOUTME: GoRouter configuration with 5 main tab routes plus loading and onboarding peer routes.
// ABOUTME: Uses refreshListenable to react to data and preferences changes.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/data_provider.dart';
import '../providers/preferences_provider.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/mapa/mapa_screen.dart';
import '../screens/o_aplikaciji/o_aplikaciji_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/opstine/opstina_detail_screen.dart';
import '../screens/opstine/opstine_screen.dart';
import '../screens/pregled/pregled_screen.dart';
import '../screens/trendovi/trendovi_screen.dart';
import 'shell.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/ucitavanje',
    refreshListenable: notifier,
    redirect: (context, state) {
      final hasData = ref.read(dataRepositoryProvider).hasValue;
      final prefs = ref.read(preferencesProvider).valueOrNull;
      final loc = state.matchedLocation;

      // /ucitavanje is the gate: hold until BOTH data and prefs are ready, then
      // dispatch to /onboarding or /pregled based on onboardingSeen. This
      // prevents a race where data loads before prefs and a first-time user
      // gets routed past onboarding.
      if (loc == '/ucitavanje') {
        if (!hasData || prefs == null) return null;
        return prefs.onboardingSeen ? '/pregled' : '/onboarding';
      }
      if (!hasData) return '/ucitavanje';
      return null;
    },
    routes: [
      GoRoute(
        path: '/ucitavanje',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/pregled',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PregledScreen()),
          ),
          GoRoute(
            path: '/opstine',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OpstineScreen()),
          ),
          GoRoute(
            path: '/opstine/:name',
            pageBuilder: (context, state) => NoTransitionPage(
              child: OpstinaDetailScreen(
                municipalityName: state.pathParameters['name']!,
              ),
            ),
          ),
          GoRoute(
            path: '/trendovi',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TrendoviScreen()),
          ),
          GoRoute(
            path: '/mapa',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MapaScreen()),
          ),
          GoRoute(
            path: '/o-aplikaciji',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OAplikacijiScreen()),
          ),
        ],
      ),
    ],
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _dataSub = ref.listen(dataRepositoryProvider, (_, __) => notifyListeners());
    _prefsSub = ref.listen(preferencesProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<List<dynamic>>> _dataSub;
  late final ProviderSubscription<AsyncValue<dynamic>> _prefsSub;

  @override
  void dispose() {
    _dataSub.close();
    _prefsSub.close();
    super.dispose();
  }
}
```

- [ ] **Step 4: Regenerate router code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/navigation/router.g.dart` regenerates without error.

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/navigation/onboarding_redirect_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 6: Run full test suite**

Run:

```bash
flutter test
```

Expected: all tests pass. (Existing router tests should still pass; the redirect logic is backward-compatible when `onboardingSeen` is true.)

- [ ] **Step 7: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues.

- [ ] **Step 8: Commit**

```bash
git add lib/navigation/router.dart lib/navigation/router.g.dart test/navigation/onboarding_redirect_test.dart
git commit -m "feat: add /onboarding route with first-launch redirect"
```

---

## Task 13: Replace static `_TabGuide` with onboarding replay tile

**Files:**
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- Modify: `test/screens/o_aplikaciji_screen_test.dart`

- [ ] **Step 1: Write failing test for the replay tile**

Append a new group at the end of `test/screens/o_aplikaciji_screen_test.dart` (before the helper class definitions):

```dart
  group('replay onboarding tile', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      PackageInfo.setMockInitialValues(
        appName: 'GeoAgro Srbija',
        packageName: 'com.serbiaOpenData.rpg_claude',
        version: '1.0.4',
        buildNumber: '9',
        buildSignature: '',
      );
    });

    testWidgets('replaces static guide with replay tile', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: const OAplikacijiScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pogledaj uvodni vodič'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      // The 'Vodič kroz aplikaciju' header is gone — its content moved into
      // the onboarding flow.
      expect(find.text('Vodič kroz aplikaciju'), findsNothing);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: the new test fails with `Expected: exactly one matching candidate ... Actually: _NoElementsFoundError`.

- [ ] **Step 3: Replace the inline `_TabGuide` block with the replay tile**

Edit `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`:

- Add import:

```dart
import 'package:go_router/go_router.dart';
```

- Add a method on `_OAplikacijiScreenState` after the existing `_openPrivacyPolicy`:

```dart
  void _openOnboarding() => context.go('/onboarding');
```

- In the `build` method, locate the block starting with `const SizedBox(height: 24)` followed by the `Vodič kroz aplikaciju` text (around line 170-204), and replace the entire block (the `Text('Vodič ...')`, the `SizedBox`, and the four `_TabGuide` widgets) with:

```dart
            const SizedBox(height: 24),
            _ActionCard(
              icon: Icons.school_outlined,
              title: 'Pogledaj uvodni vodič',
              subtitle: 'Ponovo prođi kroz vodič kroz aplikaciju',
              semanticsLabel: 'Otvori uvodni vodič kroz aplikaciju',
              onTap: _openOnboarding,
            ),
```

- Delete the now-unused `_TabGuide` widget class at the bottom of the file.

- [ ] **Step 4: Update existing tests that referenced `_TabGuide`**

Find the existing test at line 39-45 of `test/screens/o_aplikaciji_screen_test.dart`:

```dart
  testWidgets('shows guide for all 4 main tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    await tester.scrollUntilVisible(find.text('Pregled'), 100);
    expect(find.text('Pregled'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Opštine'), 100);
    expect(find.text('Opštine'), findsOneWidget);
  });
```

Replace it with:

```dart
  testWidgets('shows replay onboarding tile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const OAplikacijiScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pogledaj uvodni vodič'), findsOneWidget);
  });
```

- [ ] **Step 5: Run tests to verify they pass**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: zero issues. If there are unused imports left after removing `_TabGuide`, remove them.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/o_aplikaciji/o_aplikaciji_screen.dart test/screens/o_aplikaciji_screen_test.dart
git commit -m "feat: replace inline TabGuide with onboarding replay tile"
```

---

## Task 13.5: Render app version on "O aplikaciji" screen

**Bug (logged 2026-04-30):** `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart:93` reads `packageInfoProvider`, but the resolved `PackageInfo` is only used to gate the feedback tile and embed the version into the feedback email body. The version is never rendered as a `Text` widget, so users have no way to see which build they are running.

**Files:**
- Modify: `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`
- Modify: `test/screens/o_aplikaciji_screen_test.dart`

- [ ] **Step 1: Write failing widget test**

Add a `testWidgets` case to `test/screens/o_aplikaciji_screen_test.dart` that:

1. Sets `PackageInfo.setMockInitialValues(version: '1.0.4', buildNumber: '9', ...)` in `setUp` (or per-test).
2. Pumps `OAplikacijiScreen` inside a `ProviderScope` + `MaterialApp`.
3. `await tester.pumpAndSettle();`
4. Asserts `find.text('Verzija: v1.0.4+9'), findsOneWidget`.

Run `flutter test test/screens/o_aplikaciji_screen_test.dart` and confirm the new test fails (no version label rendered yet).

- [ ] **Step 2: Render the version label**

In `lib/screens/o_aplikaciji/o_aplikaciji_screen.dart`, inside the `Column` children list (around line 207, immediately after the last `_TabGuide` and before the closing `]`), append:

```dart
const SizedBox(height: 24),
if (packageInfo != null)
  Center(
    child: Text(
      'Verzija: v${packageInfo.version}+${packageInfo.buildNumber}',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ),
```

The `if (packageInfo != null)` guard mirrors the existing `feedbackReady` pattern — when `packageInfoProvider` is still loading or errored, the label is omitted rather than rendering a placeholder.

- [ ] **Step 3: Verify**

Run:

```bash
flutter test test/screens/o_aplikaciji_screen_test.dart
flutter analyze
dart format --set-exit-if-changed lib/screens/o_aplikaciji/o_aplikaciji_screen.dart test/screens/o_aplikaciji_screen_test.dart
```

Expected: new test passes, no analyzer issues, format check exits 0. Manual verification on device happens at the Task 14 release smoke.

---

## Task 13.6: Show intermediate ticks on line-chart x-axis

**Bug (logged 2026-04-30):** `lib/screens/trendovi/trendovi_screen.dart:375` and `lib/screens/opstine/opstina_detail_screen.dart:147` both call `dateTicks.indexOf(value)`, where `dateTicks` is a `List<double>` of `DateTime.millisecondsSinceEpoch.toDouble()` values and `value` is whatever fl_chart picks for an auto-interval tick. fl_chart's auto-interval ticks almost never coincide exactly with a millisecond timestamp, so `indexOf` returns `-1` for every label except the chart's min and max bounds (which happen to equal the first/last entries in `dateTicks`). Result: only the start and end dates render on the x-axis.

**Approach:** force fl_chart to ask for ticks at our exact `dateTicks` values by setting an explicit `interval` on the `SideTitles` and using a `nearestDateIndex` helper that returns the closest matching tick within a tolerance. The existing `idx % 3 != 0 && idx != dateTicks.length - 1` thinning logic stays unchanged.

**Files:**
- Modify: `lib/utils/chart_helpers.dart`
- Modify: `lib/screens/trendovi/trendovi_screen.dart`
- Modify: `lib/screens/opstine/opstina_detail_screen.dart`
- Modify: `test/utils/chart_helpers_test.dart` (or create if missing)

- [ ] **Step 1: Write failing tests for `nearestDateIndex`**

In `test/utils/chart_helpers_test.dart`, add a `group('nearestDateIndex')` covering:

- returns `0` when `value` exactly equals the first tick
- returns `dateTicks.length - 1` when `value` exactly equals the last tick
- returns the index of the closest tick when `value` is between two ticks
- returns `-1` when `value` is more than `(maxTick - minTick) / (dateTicks.length - 1) / 2` away from any tick
- returns `-1` when `dateTicks` is empty

Run the tests and confirm they fail (helper does not yet exist).

- [ ] **Step 2: Implement `nearestDateIndex`**

Add to `lib/utils/chart_helpers.dart`:

```dart
/// Returns the index of the tick in [dateTicks] closest to [value], or -1
/// if no tick is within half the average tick interval. Used to map
/// fl_chart's auto-interval tick values back to our discrete date list.
int nearestDateIndex(double value, List<double> dateTicks) {
  if (dateTicks.isEmpty) return -1;
  if (dateTicks.length == 1) {
    return value == dateTicks.first ? 0 : -1;
  }
  final span = dateTicks.last - dateTicks.first;
  final tolerance = span / (dateTicks.length - 1) / 2;
  var bestIdx = -1;
  var bestDist = double.infinity;
  for (var i = 0; i < dateTicks.length; i++) {
    final dist = (dateTicks[i] - value).abs();
    if (dist < bestDist) {
      bestDist = dist;
      bestIdx = i;
    }
  }
  return bestDist <= tolerance ? bestIdx : -1;
}
```

Run the tests — they should now pass.

- [ ] **Step 3: Wire `nearestDateIndex` into Trendovi**

In `lib/screens/trendovi/trendovi_screen.dart` around line 375, replace:

```dart
final idx = dateTicks.indexOf(value);
```

with:

```dart
final idx = nearestDateIndex(value, dateTicks);
```

In the same `bottomTitles` `SideTitles` (around line 371), set an explicit `interval` so fl_chart asks for ticks at our exact dates. Add `interval: dateTicks.length > 1 ? (dateTicks.last - dateTicks.first) / (dateTicks.length - 1) : null,` immediately after `reservedSize: 28,`.

- [ ] **Step 4: Wire `nearestDateIndex` into Opština detail**

In `lib/screens/opstine/opstina_detail_screen.dart` around line 147, replace `dateTicks.indexOf(value)` with `nearestDateIndex(value, dateTicks)`. Add the same `interval:` line to the `SideTitles` around line 143.

- [ ] **Step 5: Update existing chart widget tests**

The Trendovi and Opština-detail widget tests currently only check for the start/end dates. Extend them to assert that at least one intermediate date label renders. Use `find.textContaining(formatDateLabel(intermediateDate))` against a fixture with ≥4 snapshots so the `idx % 3 == 0` thinning still surfaces a middle tick.

If existing tests don't already pump charts wide enough for ticks to render, add `tester.view.physicalSize = const Size(800, 600); tester.view.devicePixelRatio = 1.0;` and reset in `tearDown`.

- [ ] **Step 6: Verify**

Run:

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed .
```

Expected: zero analyzer issues, all tests pass, format check exits 0. Manual verification on device happens at the Task 14 release smoke (look for ≥3 date labels on Trendovi and Opština-detail charts).

---

## Task 14: Release boundary 1.0.4+9

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Bump version**

Edit `pubspec.yaml` line 4 from:

```yaml
version: 1.0.3+7
```

to:

```yaml
version: 1.0.4+9
```

- [ ] **Step 2: Run analyzer, full tests, and format check**

Run:

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

Expected: zero analyzer issues, all tests pass, format check exits 0.

- [ ] **Step 3: Manual smoke (Android device)**

Build and install:

```bash
flutter build apk --release
flutter install
```

On the device, verify:
- Clear app data → open → onboarding flow shows 5 cards. Swipe and tap "Sledeće" to last card. Tap "Završi" → lands on Pregled.
- Re-open app → goes straight to Pregled (no onboarding).
- O aplikaciji → tap "Pogledaj uvodni vodič" → onboarding re-shows.
- Theme toggle: switch to Tamna → entire app re-renders dark; force-stop and restart → still dark. Switch to Sistem → follows OS appearance.
- Visual check on every screen in both brightnesses: Pregled, Opštine, Opština detail, Trendovi (incl. chart), Mapa (incl. overlay), O aplikaciji.
- O aplikaciji shows `Verzija: v1.0.4+9` below the tab guide (Task 13.5).
- Trendovi and Opština-detail line charts show ≥3 date labels along the x-axis, not just the first and last (Task 13.6).

- [ ] **Step 4: Manual smoke (web)**

Run:

```bash
flutter run -d chrome
```

Verify:
- Clear browser site data → onboarding flow shows on first visit.
- Theme toggle works.
- Native rating tile is hidden on web (it should be — `shouldShowRateTile` returns false), but the manual rate tile is also hidden on web. Confirm this matches Phase 1 behavior.

- [ ] **Step 5: Commit version bump and tag**

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.4+9"
git tag v1.0.4+9 HEAD
```

- [ ] **Step 6: Push branch and tag**

Confirm with Milan before pushing.

```bash
git push -u origin feature/dark-mode-onboarding
git push origin v1.0.4+9
```

- [ ] **Step 7: Submit Play Console internal track**

Out-of-repo. Upload the AAB to Play Console internal track.

- [ ] **Step 8: Open PR and merge to `main`**

The commit at the `v1.0.4+9` tag is what was uploaded to Play Console — `main` should reflect what was built. Open a PR from `feature/dark-mode-onboarding` into `main` summarizing the dark-mode + onboarding work plus the two `O aplikaciji` / chart bug fixes (Tasks 13.5 and 13.6) and merge it once green. Internal track is the safety net for finding regressions; keeping the feature branch open across the bake period only invites drift.
