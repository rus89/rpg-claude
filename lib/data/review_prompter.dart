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
