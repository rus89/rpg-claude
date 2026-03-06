// ABOUTME: Trendovi screen — shows active holdings over time as a line chart.
// ABOUTME: Supports filtering by municipality and organizational form.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/org_form.dart';
import '../../data/serbian_normalise.dart';
import '../../providers/data_provider.dart';
import '../../utils/chart_helpers.dart';

class TrendoviScreen extends ConsumerStatefulWidget {
  const TrendoviScreen({super.key});

  @override
  ConsumerState<TrendoviScreen> createState() => _TrendoviScreenState();
}

class _TrendoviScreenState extends ConsumerState<TrendoviScreen> {
  String? _selectedMunicipality;
  final Set<OrgForm> _selectedForms = OrgForm.values.toSet();

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;
    final allCsvNames = ref.watch(municipalityNamesProvider);
    final displayNames = resolver != null
        ? resolver.allDisplayNames
        : allCsvNames;

    return dataAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final selectedNorm = _selectedMunicipality != null
            ? normaliseSerbianName(_selectedMunicipality!)
            : null;

        final spots = snapshots.map((snapshot) {
          final records = snapshot.records.where((r) {
            final matchesMunicipality =
                selectedNorm == null ||
                (resolver?.canonicalKey(r.municipalityName) ??
                        normaliseSerbianName(r.municipalityName)) ==
                    selectedNorm;
            final matchesForm = _selectedForms.contains(r.orgForm);
            return matchesMunicipality && matchesForm;
          });
          final total = records.fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(dateToX(snapshot.date), total.toDouble());
        }).toList();

        final dateTicks = snapshots.map((s) => dateToX(s.date)).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Trendovi')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _selectedMunicipality,
                  decoration: const InputDecoration(labelText: 'Opština'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Srbija (ukupno)'),
                    ),
                    ...displayNames.map(
                      (n) => DropdownMenuItem(value: n, child: Text(n)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedMunicipality = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: OrgForm.values
                      .map(
                        (form) => FilterChip(
                          label: Text(form.displayName),
                          selected: _selectedForms.contains(form),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: _selectedForms.contains(form)
                                ? Colors.white
                                : null,
                          ),
                          checkmarkColor: Colors.white,
                          onSelected: (selected) => setState(() {
                            selected
                                ? _selectedForms.add(form)
                                : _selectedForms.remove(form);
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
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
                            return spots.map((spot) => LineTooltipItem(
                                  fmt.format(spot.y.toInt()),
                                  const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                )).toList();
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
                              // Show every 3rd label to avoid crowding
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
