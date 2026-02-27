// ABOUTME: Detail screen for a single municipality — shows active holdings by org form.
// ABOUTME: Includes a mini trend line showing active holdings across all snapshots.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/data_provider.dart';

class OpstinaDetailScreen extends ConsumerWidget {
  const OpstinaDetailScreen({super.key, required this.municipalityName});
  final String municipalityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);

    return dataAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final fmt = NumberFormat('#,###', 'sr');
        final latest = snapshots.last;
        final latestRecords = latest.records
            .where((r) => r.municipalityName == municipalityName)
            .toList();

        // Trend: total active per snapshot
        final trendSpots = snapshots.asMap().entries.map((entry) {
          final total = entry.value.records
              .where((r) => r.municipalityName == municipalityName)
              .fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(entry.key.toDouble(), total.toDouble());
        }).toList();

        return Scaffold(
          appBar: AppBar(title: Text(municipalityName)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktivna gazdinstva po obliku',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...latestRecords.map(
                  (r) => ListTile(
                    title: Text(r.orgForm.displayName),
                    trailing: Text(fmt.format(r.activeHoldings)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trend aktivnih gazdinstava',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(spots: trendSpots, isCurved: true),
                      ],
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
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
