// ABOUTME: App entry point — initialises Riverpod and launches the app.
// ABOUTME: ProviderScope wraps the entire widget tree; appOpenCount increments once per cold start.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final prefs = await container.read(preferencesProvider.future);
  await prefs.setAppOpenCount(prefs.appOpenCount + 1);
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
