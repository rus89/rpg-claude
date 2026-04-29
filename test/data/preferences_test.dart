// ABOUTME: Tests for the typed Preferences wrapper around shared_preferences.
// ABOUTME: Verifies defaults, roundtrip get/set, and themeMode raw-string encoding.

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
