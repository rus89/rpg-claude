// ABOUTME: Detail screen for a single municipality — shows active holdings by org form.
// ABOUTME: Includes a trend line showing active holdings across all snapshots.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/serbian_normalise.dart';
import '../../providers/data_provider.dart';
import '../../utils/chart_helpers.dart';

class OpstinaDetailScreen extends ConsumerWidget {
  const OpstinaDetailScreen({super.key, required this.municipalityName});
  final String municipalityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;

    return dataAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final fmt = NumberFormat('#,###', 'sr');
        final normalised = normaliseSerbianName(municipalityName);
        final latest = snapshots.last;
        final latestRecords = latest.records
            .where(
              (r) =>
                  (resolver?.canonicalKey(r.municipalityName) ??
                      normaliseSerbianName(r.municipalityName)) ==
                  normalised,
            )
            .toList();

        // Trend: total active per snapshot with proportional date x-axis
        final trendSpots = snapshots.map((snapshot) {
          final total = snapshot.records
              .where(
                (r) =>
                    (resolver?.canonicalKey(r.municipalityName) ??
                        normaliseSerbianName(r.municipalityName)) ==
                    normalised,
              )
              .fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(dateToX(snapshot.date), total.toDouble());
        }).toList();

        final dateTicks = snapshots.map((s) => dateToX(s.date)).toList();

        return Scaffold(
          appBar: AppBar(title: Text(municipalityName)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivna gazdinstva po obliku',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...latestRecords.map(
                  (r) => ListTile(
                    title: Text(r.orgForm.displayName),
                    trailing: Text(fmt.format(r.activeHoldings)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Trend aktivnih gazdinstava',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: trendSpots,
                          isCurved: false,
                          color: Theme.of(context).colorScheme.primary,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, _) {
                              final idx = dateTicks.indexOf(value);
                              if (idx < 0) return const SizedBox();
                              if (idx % 3 != 0 && idx != dateTicks.length - 1) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  formatDateLabel(snapshots[idx].date),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, _) => Text(
                              abbreviateCount(value),
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
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
