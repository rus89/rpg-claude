// ABOUTME: Full-screen loading indicator shown while CSV data is being fetched.
// ABOUTME: Shows specific error messages based on failure type, with a retry button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/fetch_error.dart';
import '../../providers/data_provider.dart';

class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return Scaffold(
      body: Center(
        child: dataAsync.when(
          loading: () => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Učitavanje podataka...'),
            ],
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(_errorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dataRepositoryProvider),
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is FetchException) return error.error.message;
    return FetchError.unknown.message;
  }
}
