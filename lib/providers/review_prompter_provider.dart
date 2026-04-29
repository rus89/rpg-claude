// ABOUTME: Riverpod provider for ReviewPrompter; depends on Preferences and PackageInfo.
// ABOUTME: Constructs the prompter once per app process via keepAlive.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/review_prompter.dart';
import 'package_info_provider.dart';
import 'preferences_provider.dart';

part 'review_prompter_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ReviewPrompter> reviewPrompter(Ref ref) async {
  final prefs = await ref.read(preferencesProvider.future);
  final info = await ref.read(packageInfoProvider.future);
  return ReviewPrompter(prefs: prefs, currentBuildNumber: info.buildNumber);
}
