// ABOUTME: Detail screen for a single municipality — shows active holdings by org form,
// ABOUTME: trend line, farm size distribution, and age structure of farm operators.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/age_bracket.dart';
import '../../data/name_resolver.dart';
import '../../data/serbian_normalise.dart';
import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../providers/age_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/farm_size_provider.dart';
import '../../utils/chart_helpers.dart';

bool _matchesMunicipality(
  String recordName,
  NameResolver? resolver,
  String normalised,
) =>
    (resolver?.canonicalKey(recordName) ??
        normaliseSerbianName(recordName)) ==
    normalised;

class OpstinaDetailScreen extends ConsumerWidget {
  const OpstinaDetailScreen({super.key, required this.municipalityName});
  final String municipalityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (snapshots) {
        final fmt = NumberFormat('#,###', 'sr');
        final normalised = normaliseSerbianName(municipalityName);
        final latest = snapshots.last;
        final latestRecords = latest.records
            .where(
              (r) => _matchesMunicipality(
                r.municipalityName,
                resolver,
                normalised,
              ),
            )
            .toList();

        // Trend: total active per snapshot with proportional date x-axis
        final trendSpots = snapshots.map((snapshot) {
          final total = snapshot.records
              .where(
                (r) => _matchesMunicipality(
                  r.municipalityName,
                  resolver,
                  normalised,
                ),
              )
              .fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(dateToX(snapshot.date), total.toDouble());
        }).toList();

        final dateTicks = snapshots.map((s) => dateToX(s.date)).toList();

        final desktop = isDesktop(context);
        final chartHeight = desktop ? 280.0 : 160.0;

        final orgFormSection = Column(
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
          ],
        );

        final chartSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend aktivnih gazdinstava',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: chartHeight,
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
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          const Color.fromARGB(255, 237, 191, 136),
                      getTooltipItems: (spots) {
                        final fmt = NumberFormat('#,###', 'sr');
                        return spots
                            .map(
                              (spot) => LineTooltipItem(
                                fmt.format(spot.y.toInt()),
                                const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            )
                            .toList();
                      },
                    ),
                  ),
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
        );

        return ScreenScaffold(
          title: municipalityName,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: orgFormSection),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: chartSection),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          orgFormSection,
                          const SizedBox(height: 24),
                          chartSection,
                        ],
                      ),
                const SizedBox(height: 24),
                _FarmSizeDetail(municipalityName: municipalityName),
                const SizedBox(height: 24),
                _AgeDetail(municipalityName: municipalityName),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FarmSizeDetail extends ConsumerWidget {
  const _FarmSizeDetail({required this.municipalityName});
  final String municipalityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(farmSizeRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;
    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshots) {
        if (snapshots.isEmpty) return const SizedBox.shrink();
        final latest = snapshots.last;
        final normalised = normaliseSerbianName(municipalityName);
        final matches = latest.records.where(
          (r) => _matchesMunicipality(
            r.municipalityName,
            resolver,
            normalised,
          ),
        );
        if (matches.isEmpty) return const SizedBox.shrink();
        final record = matches.first;

        final fmt = NumberFormat('#,##0.0', 'sr');
        final brackets = [
          ('≤5 ha', record.countUpTo5),
          ('5–20 ha', record.count5to20),
          ('20–100 ha', record.count20to100),
          ('>100 ha', record.countOver100),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veličina gazdinstava',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (var i = 0; i < brackets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: brackets[i].$2.toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                            width: 22,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= brackets.length) {
                            return const SizedBox();
                          }
                          return Text(
                            brackets[idx].$1,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
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
            const SizedBox(height: 8),
            Text(
              'Ukupna površina: ${fmt.format(record.totalArea)} ha',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _AgeDetail extends ConsumerWidget {
  const _AgeDetail({required this.municipalityName});
  final String municipalityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(ageRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;
    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshots) {
        if (snapshots.isEmpty) return const SizedBox.shrink();
        final latest = snapshots.last;
        final normalised = normaliseSerbianName(municipalityName);
        final records = latest.records.where(
          (r) => _matchesMunicipality(
            r.municipalityName,
            resolver,
            normalised,
          ),
        );
        if (records.isEmpty) return const SizedBox.shrink();

        final byBracket = <AgeBracket, int>{};
        for (final r in records) {
          byBracket[r.ageBracket] =
              (byBracket[r.ageBracket] ?? 0) + r.farmCount;
        }

        // Sort by enum index so bars appear in age order
        final sorted = byBracket.entries.toList()
          ..sort((a, b) => a.key.index.compareTo(b.key.index));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starosna struktura nosioca',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (var i = 0; i < sorted.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: sorted[i].value.toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                            width: 22,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sorted.length) {
                            return const SizedBox();
                          }
                          return Text(
                            sorted[idx].key.displayName,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
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
        );
      },
    );
  }
}
