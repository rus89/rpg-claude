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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretraži opštine...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
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
