// ABOUTME: Responsive scaffold wrapper — replaces raw Scaffold in every screen.
// ABOUTME: Mobile renders Scaffold+AppBar; desktop renders constrained body only.

import 'package:flutter/material.dart';

import 'breakpoints.dart';

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.fullWidth = false,
  });

  final String title;
  final Widget child;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    if (!isDesktop(context)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
      );
    }

    if (fullWidth) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}
