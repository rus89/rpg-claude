// ABOUTME: Typed wrapper around SharedPreferences keyed by domain concepts.
// ABOUTME: Hides string keys and provides typed get/set per preference.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Preferences(this._prefs);

  static const _kThemeMode = 'themeMode';
  static const _kOnboardingSeen = 'onboardingSeen';
  static const _kAppOpenCount = 'appOpenCount';
  static const _kLastReviewPromptDate = 'lastReviewPromptDate';
  static const _kReviewPromptedForBuild = 'reviewPromptedForBuild';

  final SharedPreferences _prefs;

  ThemeMode get themeMode => switch (_prefs.getString(_kThemeMode)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

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
