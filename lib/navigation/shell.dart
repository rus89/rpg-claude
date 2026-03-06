// ABOUTME: Navigation shell — wraps all main tab screens.
// ABOUTME: Mobile shows bottom nav bar; desktop shows top AppBar with text buttons.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/breakpoints.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    ('Pregled', '/pregled'),
    ('Opštine', '/opstine'),
    ('Trendovi', '/trendovi'),
    ('Mapa', '/mapa'),
    ('O aplikaciji', '/o-aplikaciji'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFor(location);

    if (isDesktop(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('RPG Srbija'),
          actions: [
            for (var i = 0; i < _destinations.length; i++)
              _NavButton(
                label: _destinations[i].$1,
                isActive: i == currentIndex,
                onTap: () => context.go(_destinations[i].$2),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: child,
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) =>
            context.go(_destinations[index].$2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Pregled'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Opštine'),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Trendovi',
          ),
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            label: 'O aplikaciji',
          ),
        ],
      ),
    );
  }

  int _indexFor(String location) => switch (location) {
    '/pregled' => 0,
    '/opstine' => 1,
    '/trendovi' => 2,
    '/mapa' => 3,
    '/o-aplikaciji' => 4,
    _ => 0,
  };
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final foreground = Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? primary : foreground,
        backgroundColor: isActive ? foreground : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
