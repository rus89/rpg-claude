// ABOUTME: Opštine screen — searchable list of all municipalities in the dataset.
// ABOUTME: Tapping a municipality navigates to its detail screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data_provider.dart';

class OpstineScreen extends ConsumerStatefulWidget {
  const OpstineScreen({super.key});

  @override
  ConsumerState<OpstineScreen> createState() => _OpstineScreenState();
}

class _OpstineScreenState extends ConsumerState<OpstineScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final resolverAsync = ref.watch(nameResolverProvider);
    final allCsvNames = ref.watch(municipalityNamesProvider);

    final resolver = resolverAsync.valueOrNull;
    final displayNames = resolver != null
        ? resolver.allDisplayNames
        : allCsvNames;
    final filtered = displayNames
        .where((n) => n.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Opštine')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pretraži opštine...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final name = filtered[index];
                return ListTile(
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/opstine/$name'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
