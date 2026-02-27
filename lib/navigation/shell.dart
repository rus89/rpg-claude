// ABOUTME: Bottom navigation shell widget — wraps all main tab screens.
// ABOUTME: Highlights the active tab and handles tab switching via GoRouter.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_pathFor(index)),
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

  String _pathFor(int index) => switch (index) {
    0 => '/pregled',
    1 => '/opstine',
    2 => '/trendovi',
    3 => '/mapa',
    4 => '/o-aplikaciji',
    _ => '/pregled',
  };
}
