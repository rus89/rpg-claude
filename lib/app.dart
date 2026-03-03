// ABOUTME: Root widget — configures MaterialApp with GoRouter and Serbian locale.
// ABOUTME: Watches the router provider to wire GoRouter into the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/router.dart';
import 'theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'RPG Srbija',
      routerConfig: router,
      theme: appTheme,
    );
  }
}
