// ABOUTME: Full-screen loading indicator shown while CSV data is being fetched.
// ABOUTME: Shows error message and retry button if the fetch fails.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              const Text('Greška pri učitavanju podataka'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(dataRepositoryProvider),
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
          data: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
