// ABOUTME: Trendovi screen — shows trend lines for farm counts, farm sizes, and age structure.
// ABOUTME: Supports filtering by municipality, organizational form, size bracket, or age bracket.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/age_bracket.dart';
import '../../data/models/age_snapshot.dart';
import '../../data/models/farm_size_snapshot.dart';
import '../../data/models/org_form.dart';
import '../../data/models/snapshot.dart';
import '../../data/name_resolver.dart';
import '../../data/serbian_normalise.dart';
import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../providers/age_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/farm_size_provider.dart';
import '../../utils/chart_helpers.dart';

enum _Dataset { gazdinstva, velicina, starost }

class TrendoviScreen extends ConsumerStatefulWidget {
  const TrendoviScreen({super.key});

  @override
  ConsumerState<TrendoviScreen> createState() => _TrendoviScreenState();
}

class _TrendoviScreenState extends ConsumerState<TrendoviScreen> {
  String? _selectedMunicipality;
  final Set<OrgForm> _selectedForms = OrgForm.values.toSet();
  _Dataset _selectedDataset = _Dataset.gazdinstva;
  final Set<int> _selectedSizeBrackets = {0, 1, 2, 3};
  final Set<AgeBracket> _selectedAgeBrackets = AgeBracket.values.toSet();

  String? get _selectedNorm => _selectedMunicipality != null
      ? normaliseSerbianName(_selectedMunicipality!)
      : null;

  bool _matchesMunicipality(String recordName, NameResolver? resolver) {
    if (_selectedNorm == null) return true;
    return (resolver?.canonicalKey(recordName) ??
            normaliseSerbianName(recordName)) ==
        _selectedNorm;
  }

  Widget _buildFilterChips<T>({
    required BuildContext context,
    required List<T> values,
    required String Function(T) label,
    required Set<T> selected,
  }) {
    return Wrap(
      spacing: 8,
      children: values
          .map(
            (v) => FilterChip(
              label: Text(label(v)),
              selected: selected.contains(v),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: selected.contains(v) ? Colors.white : null,
              ),
              checkmarkColor: Colors.white,
              onSelected: (isSelected) => setState(() {
                isSelected ? selected.add(v) : selected.remove(v);
              }),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;
    final allCsvNames = ref.watch(municipalityNamesProvider);
    final displayNames = resolver != null
        ? resolver.allDisplayNames
        : allCsvNames;

    final farmSizeAsync = _selectedDataset == _Dataset.velicina
        ? ref.watch(farmSizeRepositoryProvider)
        : null;
    final ageAsync = _selectedDataset == _Dataset.starost
        ? ref.watch(ageRepositoryProvider)
        : null;

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (snapshots) {
        return ScreenScaffold(
          title: 'Trendovi',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<_Dataset>(
                    segments: const [
                      ButtonSegment(
                        value: _Dataset.gazdinstva,
                        label: Text('Gazdinstva'),
                      ),
                      ButtonSegment(
                        value: _Dataset.velicina,
                        label: Text('Veličina'),
                      ),
                      ButtonSegment(
                        value: _Dataset.starost,
                        label: Text('Starost'),
                      ),
                    ],
                    selected: {_selectedDataset},
                    onSelectionChanged: (selected) => setState(() {
                      _selectedDataset = selected.first;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedMunicipality,
                  decoration: const InputDecoration(labelText: 'Opština'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Srbija (ukupno)'),
                    ),
                    ...displayNames.map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text(
                          n,
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedMunicipality = v),
                ),
                const SizedBox(height: 12),
                if (_selectedDataset == _Dataset.gazdinstva)
                  _buildFilterChips(
                    context: context,
                    values: OrgForm.values,
                    label: (f) => f.displayName,
                    selected: _selectedForms,
                  )
                else if (_selectedDataset == _Dataset.velicina)
                  _buildFilterChips(
                    context: context,
                    values: const [0, 1, 2, 3],
                    label: (i) =>
                        const ['≤5 ha', '5–20 ha', '20–100 ha', '>100 ha'][i],
                    selected: _selectedSizeBrackets,
                  )
                else
                  _buildFilterChips(
                    context: context,
                    values: AgeBracket.values,
                    label: (b) => b.displayName,
                    selected: _selectedAgeBrackets,
                  ),
                const SizedBox(height: 24),
                if (_selectedDataset == _Dataset.gazdinstva)
                  _buildGazdinstvaChart(context, snapshots, resolver)
                else if (_selectedDataset == _Dataset.velicina)
                  _buildVelicinaChart(context, farmSizeAsync!, resolver)
                else
                  _buildStarostChart(context, ageAsync!, resolver),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGazdinstvaChart(
    BuildContext context,
    List<Snapshot> snapshots,
    NameResolver? resolver,
  ) {
    final spots = snapshots.map((snapshot) {
      final records = snapshot.records.where((r) {
        return _matchesMunicipality(r.municipalityName, resolver) &&
            _selectedForms.contains(r.orgForm);
      });
      final total = records.fold(0, (sum, r) => sum + r.activeHoldings);
      return FlSpot(dateToX(snapshot.date), total.toDouble());
    }).toList();

    final dates = snapshots.map((s) => s.date).toList();
    return _buildChart(context, spots, dates);
  }

  Widget _buildVelicinaChart(
    BuildContext context,
    AsyncValue<List<FarmSizeSnapshot>> farmSizeAsync,
    NameResolver? resolver,
  ) {
    return farmSizeAsync.when(
      loading: () => const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SizedBox(height: 280, child: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final spots = snapshots.map((snapshot) {
          var total = 0;
          for (final r in snapshot.records) {
            if (!_matchesMunicipality(r.municipalityName, resolver)) continue;
            if (_selectedSizeBrackets.contains(0)) total += r.countUpTo5;
            if (_selectedSizeBrackets.contains(1)) total += r.count5to20;
            if (_selectedSizeBrackets.contains(2)) total += r.count20to100;
            if (_selectedSizeBrackets.contains(3)) total += r.countOver100;
          }
          return FlSpot(dateToX(snapshot.date), total.toDouble());
        }).toList();

        final dates = snapshots.map((s) => s.date).toList();
        return _buildChart(context, spots, dates);
      },
    );
  }

  Widget _buildStarostChart(
    BuildContext context,
    AsyncValue<List<AgeSnapshot>> ageAsync,
    NameResolver? resolver,
  ) {
    return ageAsync.when(
      loading: () => const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SizedBox(height: 280, child: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final spots = snapshots.map((snapshot) {
          final total = snapshot.records
              .where((r) {
                return _matchesMunicipality(r.municipalityName, resolver) &&
                    _selectedAgeBrackets.contains(r.ageBracket);
              })
              .fold(0, (sum, r) => sum + r.farmCount);
          return FlSpot(dateToX(snapshot.date), total.toDouble());
        }).toList();

        final dates = snapshots.map((s) => s.date).toList();
        return _buildChart(context, spots, dates);
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<FlSpot> spots,
    List<DateTime> dates,
  ) {
    final dateTicks = dates.map((d) => dateToX(d)).toList();
    return SizedBox(
      height: isDesktop(context) ? 400 : 280,
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
              getTooltipColor: (_) => const Color.fromARGB(255, 237, 191, 136),
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
                      formatDateLabel(dates[idx]),
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
    );
  }
}
