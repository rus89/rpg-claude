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

    test(
      'true when count >= 3, no prior build prompt, no recent date',
      () async {
        final prefs = await _prefsWith({'appOpenCount': 3});
        final prompter = ReviewPrompter(
          prefs: prefs,
          currentBuildNumber: '6',
          review: _FakeReview(),
          now: () => DateTime.utc(2026, 4, 29),
        );
        expect(prompter.isEligible, isTrue);
      },
    );

    test('true when last prompt was 30 days ago and build differs', () async {
      final prefs = await _prefsWith({
        'appOpenCount': 5,
        'reviewPromptedForBuild': '5',
        'lastReviewPromptDate': DateTime.utc(2026, 3, 30).toIso8601String(),
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

    test(
      'calls requestReview and persists date + build when eligible',
      () async {
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
      },
    );

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
