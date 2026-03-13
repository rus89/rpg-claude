// ABOUTME: Pregled (overview) screen showing national RPG totals for the latest snapshot.
// ABOUTME: Displays summary cards, bar chart, municipality rankings, farm size distribution, and age structure.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/age_bracket.dart';
import '../../data/models/org_form.dart';
import '../../data/models/snapshot.dart';
import '../../data/name_resolver.dart';
import '../../data/serbian_normalise.dart';
import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../providers/age_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/farm_size_provider.dart';
import '../../theme.dart';

class PregledScreen extends ConsumerWidget {
  const PregledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return const Center(child: Text('Nema podataka'));
        }
        return ScreenScaffold(
          title: 'Pregled',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _PregledBody(snapshots: snapshots, resolver: resolver),
          ),
        );
      },
    );
  }
}

class _PregledBody extends StatelessWidget {
  const _PregledBody({required this.snapshots, this.resolver});

  final List<Snapshot> snapshots;
  final NameResolver? resolver;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'sr');
    final latest = snapshots.last;
    final hasPrevious = snapshots.length > 1;
    final previous = hasPrevious ? snapshots[snapshots.length - 2] : null;

    final totalRegistered = latest.records.fold(
      0,
      (sum, r) => sum + r.totalRegistered,
    );
    final totalActive = latest.records.fold(
      0,
      (sum, r) => sum + r.activeHoldings,
    );

    final prevRegistered = previous?.records.fold(
      0,
      (sum, r) => sum + r.totalRegistered,
    );
    final prevActive = previous?.records.fold(
      0,
      (sum, r) => sum + r.activeHoldings,
    );

    final activityRate = totalRegistered > 0
        ? totalActive / totalRegistered * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Podaci na dan: ${DateFormat('dd.MM.yyyy').format(latest.date)}'),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Ukupno registrovanih',
                  value: fmt.format(totalRegistered),
                  delta: _delta(totalRegistered, prevRegistered),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Aktivnih gazdinstava',
                  value: fmt.format(totalActive),
                  delta: _delta(totalActive, prevActive),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Stopa aktivnosti',
                  value:
                      '${activityRate.toStringAsFixed(1).replaceAll('.', ',')}%',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _BarChartSection(latest: latest),
        const SizedBox(height: 24),
        _MunicipalityRankings(snapshots: snapshots, resolver: resolver),
        const SizedBox(height: 24),
        const _FarmSizeSummary(),
        const SizedBox(height: 24),
        const _AgeSummary(),
      ],
    );
  }

  String? _delta(int current, int? prev) {
    if (prev == null || prev == 0) return null;
    final pct = (current - prev) / prev * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1).replaceAll('.', ',')}%';
  }
}

class _FarmSizeSummary extends ConsumerWidget {
  const _FarmSizeSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(farmSizeRepositoryProvider);
    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshots) {
        if (snapshots.isEmpty) return const SizedBox.shrink();
        final latest = snapshots.last;

        final totalFarms = latest.records.fold(
          0,
          (sum, r) => sum + r.totalFarms,
        );
        final totalArea = latest.records.fold(
          0.0,
          (sum, r) => sum + r.totalArea,
        );
        final avgSize = totalFarms > 0 ? totalArea / totalFarms : 0.0;

        final countUpTo5 = latest.records.fold(
          0,
          (sum, r) => sum + r.countUpTo5,
        );
        final count5to20 = latest.records.fold(
          0,
          (sum, r) => sum + r.count5to20,
        );
        final count20to100 = latest.records.fold(
          0,
          (sum, r) => sum + r.count20to100,
        );
        final countOver100 = latest.records.fold(
          0,
          (sum, r) => sum + r.countOver100,
        );

        final brackets = [
          ('≤5 ha', countUpTo5, 0.3),
          ('5–20 ha', count5to20, 0.5),
          ('20–100 ha', count20to100, 0.7),
          ('>100 ha', countOver100, 1.0),
        ];

        final primary = Theme.of(context).colorScheme.primary;
        final avgFormatted = avgSize.toStringAsFixed(1).replaceAll('.', ',');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veličina gazdinstava',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: cardDecoration,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prosečna veličina: $avgFormatted ha',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: brackets
                            .where((b) => b.$2 > 0)
                            .map(
                              (b) => Expanded(
                                flex: b.$2,
                                child: Container(
                                  height: 28,
                                  color: primary.withValues(alpha: b.$3),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: brackets
                          .map(
                            (b) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: b.$3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${b.$1}: ${(b.$2 / totalFarms * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AgeSummary extends ConsumerWidget {
  const _AgeSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(ageRepositoryProvider);
    return asyncValue.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshots) {
        if (snapshots.isEmpty) return const SizedBox.shrink();
        final latest = snapshots.last;

        var totalCount = 0;
        var weightedSum = 0.0;
        for (final r in latest.records) {
          totalCount += r.farmCount;
          weightedSum += r.farmCount * r.ageBracket.midpoint;
        }
        final avgAge = totalCount > 0 ? weightedSum / totalCount : 0.0;

        final byBracket = <AgeBracket, int>{};
        for (final r in latest.records) {
          byBracket[r.ageBracket] =
              (byBracket[r.ageBracket] ?? 0) + r.farmCount;
        }

        final sortedBrackets = byBracket.entries.toList()
          ..sort((a, b) => a.key.index.compareTo(b.key.index));

        final maxCount = sortedBrackets.fold(
          0,
          (max, e) => e.value > max ? e.value : max,
        );

        final primary = Theme.of(context).colorScheme.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starosna struktura nosioca',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: cardDecoration,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prosečna starost: ${avgAge.round()} godina',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: isDesktop(context) ? 280 : 200,
                      child: BarChart(
                        BarChartData(
                          maxY: maxCount * 1.15,
                          barGroups: sortedBrackets
                              .asMap()
                              .entries
                              .map(
                                (entry) => BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.value.toDouble(),
                                      width: 16,
                                      color: primary,
                                    ),
                                  ],
                                  showingTooltipIndicators:
                                      entry.value.value > 0 ? [0] : [],
                                ),
                              )
                              .toList(),
                          barTouchData: BarTouchData(
                            enabled: false,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) =>
                                  const Color.fromARGB(255, 237, 191, 136),
                              fitInsideVertically: true,
                              fitInsideHorizontally: true,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final fmt = NumberFormat('#,###', 'sr');
                                    return BarTooltipItem(
                                      fmt.format(rod.toY.toInt()),
                                      TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isDesktop(context)
                                            ? 11.0
                                            : 9.0,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= sortedBrackets.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      sortedBrackets[idx].key.displayName,
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
            ),
          ],
        );
      },
    );
  }
}

class _BarChartSection extends StatelessWidget {
  const _BarChartSection({required this.latest});

  final Snapshot latest;

  @override
  Widget build(BuildContext context) {
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
        showingTooltipIndicators: value > 0 ? [0] : [],
      );
    }).toList();

    final maxValue = byOrgForm.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivna gazdinstva po obliku organizacije',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: isDesktop(context) ? 360 : 240,
          child: BarChart(
            BarChartData(
              maxY: maxValue * 1.15,
              barGroups: barGroups,
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      const Color.fromARGB(255, 237, 191, 136),
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final fmt = NumberFormat('#,###', 'sr');
                    return BarTooltipItem(
                      fmt.format(rod.toY.toInt()),
                      TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop(context) ? 11.0 : 9.0,
                      ),
                    );
                  },
                ),
              ),
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
    );
  }
}

class _MunicipalityRankings extends StatelessWidget {
  const _MunicipalityRankings({required this.snapshots, this.resolver});

  final List<Snapshot> snapshots;
  final NameResolver? resolver;

  @override
  Widget build(BuildContext context) {
    final latest = snapshots.last;
    final first = snapshots.first;
    final fmt = NumberFormat('#,###', 'sr');

    // Aggregate active holdings by municipality (normalised key)
    final latestByMunicipality = _aggregateActive(latest);
    final firstByMunicipality = _aggregateActive(first);

    // Top 5 by active count
    final topActive = latestByMunicipality.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final top5Active = topActive.take(5).toList();

    // Growth rates
    final growthRates = <_MunicipalityGrowth>[];
    for (final entry in latestByMunicipality.entries) {
      final firstEntry = firstByMunicipality[entry.key];
      if (firstEntry == null || firstEntry.count == 0) continue;
      final growth =
          (entry.value.count - firstEntry.count) / firstEntry.count * 100;
      growthRates.add(
        _MunicipalityGrowth(
          displayName: entry.value.displayName,
          growth: growth,
        ),
      );
    }

    growthRates.sort((a, b) => b.growth.compareTo(a.growth));
    final top5Growth = growthRates.where((g) => g.growth > 0).take(5).toList();
    final bottom5Decline = growthRates
        .where((g) => g.growth < 0)
        .toList()
        .reversed
        .take(5)
        .toList();

    final topActiveSection = _RankingSection(
      title: 'Top 5 opština po broju aktivnih',
      items: top5Active
          .map(
            (e) => _RankingItem(
              name: e.value.displayName,
              trailing: fmt.format(e.value.count),
              onTap: () => context.push('/opstine/${e.value.displayName}'),
            ),
          )
          .toList(),
    );

    final growthSection = _RankingSection(
      title: 'Top 5 opština po rastu',
      items: top5Growth
          .map(
            (g) => _RankingItem(
              name: g.displayName,
              trailing: '+${g.growth.toStringAsFixed(1).replaceAll('.', ',')}%',
              trailingColor: Colors.green.shade700,
            ),
          )
          .toList(),
    );

    final declineSection = _RankingSection(
      title: 'Opštine u opadanju',
      items: bottom5Decline
          .map(
            (g) => _RankingItem(
              name: g.displayName,
              trailing: '${g.growth.toStringAsFixed(1).replaceAll('.', ',')}%',
              trailingColor: Colors.red.shade700,
            ),
          )
          .toList(),
    );

    final hasMultiple = snapshots.length > 1;

    if (isDesktop(context) && hasMultiple) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: topActiveSection),
            const SizedBox(width: 16),
            Expanded(child: growthSection),
            const SizedBox(width: 16),
            Expanded(child: declineSection),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        topActiveSection,
        if (hasMultiple) ...[
          const SizedBox(height: 24),
          growthSection,
          const SizedBox(height: 24),
          declineSection,
        ],
      ],
    );
  }

  Map<String, _MunicipalityCount> _aggregateActive(Snapshot snapshot) {
    final map = <String, _MunicipalityCount>{};
    for (final r in snapshot.records) {
      final key =
          resolver?.canonicalKey(r.municipalityName) ??
          normaliseSerbianName(r.municipalityName);
      final existing = map[key];
      final display =
          resolver?.displayName(r.municipalityName) ?? r.municipalityName;
      map[key] = _MunicipalityCount(
        displayName: existing?.displayName ?? display,
        count: (existing?.count ?? 0) + r.activeHoldings,
      );
    }
    return map;
  }
}

class _MunicipalityCount {
  const _MunicipalityCount({required this.displayName, required this.count});
  final String displayName;
  final int count;
}

class _MunicipalityGrowth {
  const _MunicipalityGrowth({required this.displayName, required this.growth});
  final String displayName;
  final double growth;
}

class _RankingSection extends StatelessWidget {
  const _RankingSection({required this.title, required this.items});
  final String title;
  final List<_RankingItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: cardDecoration,
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _RankingItem extends StatelessWidget {
  const _RankingItem({
    required this.name,
    required this.trailing,
    this.trailingColor,
    this.onTap,
  });
  final String name;
  final String trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      trailing: Text(
        trailing,
        style: TextStyle(fontWeight: FontWeight.w600, color: trailingColor),
      ),
      onTap: onTap,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, this.delta});
  final String label;
  final String value;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta != null && delta!.startsWith('+');
    return DecoratedBox(
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (delta != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: isPositive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    delta!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
