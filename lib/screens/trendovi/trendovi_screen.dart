// ABOUTME: Trendovi screen — shows active holdings over time as a line chart.
// ABOUTME: Supports filtering by municipality and organizational form.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/org_form.dart';
import '../../providers/data_provider.dart';

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
    final allNames = ref.watch(municipalityNamesProvider);

    return dataAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final spots = snapshots.asMap().entries.map((entry) {
          final records = entry.value.records.where((r) {
            final matchesMunicipality =
                _selectedMunicipality == null ||
                r.municipalityName == _selectedMunicipality;
            final matchesForm = _selectedForms.contains(r.orgForm);
            return matchesMunicipality && matchesForm;
          });
          final total = records.fold(0, (sum, r) => sum + r.activeHoldings);
          return FlSpot(entry.key.toDouble(), total.toDouble());
        }).toList();

        final xLabels = snapshots
            .map((s) => DateFormat('MM/yy').format(s.date))
            .toList();

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
                    ...allNames.map(
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
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= xLabels.length) {
                                return const SizedBox();
                              }
                              return Text(
                                xLabels[idx],
                                style: const TextStyle(fontSize: 9),
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
