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
