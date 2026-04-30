// ABOUTME: Riverpod provider for the Preferences wrapper.
// ABOUTME: Resolves SharedPreferences once per app process via keepAlive.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/preferences.dart';

part 'preferences_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Preferences> preferences(Ref ref) async {
  final raw = await SharedPreferences.getInstance();
  return Preferences(raw);
}
