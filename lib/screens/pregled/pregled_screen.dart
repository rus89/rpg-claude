// ABOUTME: Pregled (overview) screen showing national RPG totals for the latest snapshot.
// ABOUTME: Displays summary cards and a bar chart broken down by organizational form.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/org_form.dart';
import '../../providers/data_provider.dart';

class PregledScreen extends ConsumerWidget {
  const PregledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return dataAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return const Scaffold(body: Center(child: Text('Nema podataka')));
        }
        final latest = snapshots.last;
        final totalRegistered = latest.records.fold(
          0,
          (sum, r) => sum + r.totalRegistered,
        );
        final totalActive = latest.records.fold(
          0,
          (sum, r) => sum + r.activeHoldings,
        );
        final fmt = NumberFormat('#,###', 'sr');

        final byOrgForm = <OrgForm, int>{};
        for (final r in latest.records) {
          byOrgForm[r.orgForm] = (byOrgForm[r.orgForm] ?? 0) + r.activeHoldings;
        }

        final barGroups = OrgForm.values.asMap().entries.map((entry) {
          final value = byOrgForm[entry.value] ?? 0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: value.toDouble(),
                width: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Pregled')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podaci na dan: ${DateFormat('dd.MM.yyyy').format(latest.date)}',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Ukupno registrovanih',
                        value: fmt.format(totalRegistered),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Aktivnih gazdinstava',
                        value: fmt.format(totalActive),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aktivna gazdinstva po obliku organizacije',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final form = OrgForm.values[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  form.displayName.split(' ').first,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
