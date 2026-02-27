// ABOUTME: GoRouter configuration with 5 main tab routes.
// ABOUTME: Uses refreshListenable so the router is created once and never recreated.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../providers/data_provider.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/mapa/mapa_screen.dart';
import '../screens/o_aplikaciji/o_aplikaciji_screen.dart';
import '../screens/opstine/opstina_detail_screen.dart';
import '../screens/opstine/opstine_screen.dart';
import '../screens/pregled/pregled_screen.dart';
import '../screens/trendovi/trendovi_screen.dart';
import 'shell.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final notifier = _DataLoadingNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/ucitavanje',
    refreshListenable: notifier,
    redirect: (context, state) {
      final hasData = ref.read(dataRepositoryProvider).hasValue;
      final isOnLoading = state.matchedLocation == '/ucitavanje';
      if (!hasData && !isOnLoading) return '/ucitavanje';
      if (hasData && isOnLoading) return '/pregled';
      return null;
    },
    routes: [
      GoRoute(
        path: '/ucitavanje',
        builder: (context, state) => const LoadingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/pregled',
            builder: (context, state) => const PregledScreen(),
          ),
          GoRoute(
            path: '/opstine',
            builder: (context, state) => const OpstineScreen(),
          ),
          GoRoute(
            path: '/opstine/:name',
            builder: (context, state) => OpstinaDetailScreen(
              municipalityName: state.pathParameters['name']!,
            ),
          ),
          GoRoute(
            path: '/trendovi',
            builder: (context, state) => const TrendoviScreen(),
          ),
          GoRoute(
            path: '/mapa',
            builder: (context, state) => const MapaScreen(),
          ),
          GoRoute(
            path: '/o-aplikaciji',
            builder: (context, state) => const OAplikacijiScreen(),
          ),
        ],
      ),
    ],
  );
}

// Listens to dataRepositoryProvider and notifies GoRouter to re-evaluate redirects.
class _DataLoadingNotifier extends ChangeNotifier {
  _DataLoadingNotifier(Ref ref) {
    _subscription = ref.listen(dataRepositoryProvider, (_, __) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AsyncValue<List<dynamic>>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
