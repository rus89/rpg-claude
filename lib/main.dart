// ABOUTME: App entry point — initialises Riverpod and launches the app.
// ABOUTME: ProviderScope wraps the entire widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}
