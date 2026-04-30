// ABOUTME: Widget tests for the loading screen.
// ABOUTME: Covers loading, error, and retry states.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_claude/data/fetch_error.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/loading/loading_screen.dart';

void main() {
  testWidgets('shows progress indicator while loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _NeverCompleteRepository()),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message and retry button on failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FailingRepository()),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FetchError.unknown.message), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
  });

  testWidgets('shows no-internet message when FetchException is noInternet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _FetchErrorRepository(FetchError.noInternet),
          ),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FetchError.noInternet.message), findsOneWidget);
  });

  testWidgets('shows timeout message when FetchException is timeout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _FetchErrorRepository(FetchError.timeout),
          ),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FetchError.timeout.message), findsOneWidget);
  });

  testWidgets('shows server error message for serverError', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(
            () => _FetchErrorRepository(FetchError.serverError),
          ),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FetchError.serverError.message), findsOneWidget);
  });

  testWidgets('shows generic message for non-FetchException errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _FailingRepository()),
        ],
        child: const MaterialApp(home: LoadingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(FetchError.unknown.message), findsOneWidget);
  });
}

class _NeverCompleteRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() => Completer<List<Snapshot>>().future;
}

class _FailingRepository extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => throw Exception('Network error');
}

class _FetchErrorRepository extends DataRepository {
  _FetchErrorRepository(this.errorType);
  final FetchError errorType;

  @override
  Future<List<Snapshot>> build() async => throw FetchException(errorType);
}
