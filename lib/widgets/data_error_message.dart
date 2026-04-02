// ABOUTME: Reusable widget showing a data unavailability message with optional retry.
// ABOUTME: Used across screens where secondary datasets may fail to load.

import 'package:flutter/material.dart';

class DataErrorMessage extends StatelessWidget {
  const DataErrorMessage({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
