// ABOUTME: Mapa screen — choropleth map of Serbia coloured by selectable metric per municipality.
// ABOUTME: Supports farm count, average size, average age, and % young operators via metric selector.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/age_bracket.dart';
import '../../data/models/age_snapshot.dart';
import '../../data/models/farm_size_snapshot.dart';
import '../../data/models/record.dart';
import '../../data/models/snapshot.dart';
import '../../data/name_resolver.dart';
import '../../data/serbian_normalise.dart';
import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../providers/age_provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/farm_size_provider.dart';

enum MapMetric { gazdinstva, velicina, starost, mladji }

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key, this.tileProvider, this.hitNotifier});

  final TileProvider? tileProvider;
  final LayerHitNotifier<Object>? hitNotifier;

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  // Approximate bounding box for Serbia
  static final _serbiaBounds = LatLngBounds(
    const LatLng(42.23, 18.82),
    const LatLng(46.19, 23.01),
  );
  Map<String, dynamic>? _geoJson;
  String? _tappedMunicipality;
  MapMetric _selectedMetric = MapMetric.gazdinstva;
  late final LayerHitNotifier<Object> _hitNotifier;
  late final bool _ownsNotifier;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _ownsNotifier = widget.hitNotifier == null;
    _hitNotifier = widget.hitNotifier ?? ValueNotifier(null);
    _loadGeoJson();
    _hitNotifier.addListener(_onPolygonHit);
  }

  @override
  void dispose() {
    _hitNotifier.removeListener(_onPolygonHit);
    if (_ownsNotifier) _hitNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onPolygonHit() {
    final result = _hitNotifier.value;
    if (result != null && result.hitValues.isNotEmpty) {
      setState(() => _tappedMunicipality = result.hitValues.first as String);
    } else {
      setState(() => _tappedMunicipality = null);
    }
  }

  Future<void> _loadGeoJson() async {
    final raw = await rootBundle.loadString(
      'assets/geojson/serbia_municipalities.geojson',
    );
    if (mounted) {
      setState(() => _geoJson = jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dataRepositoryProvider);
    final resolver = ref.watch(nameResolverProvider).valueOrNull;

    final farmSizeAsync = _selectedMetric == MapMetric.velicina
        ? ref.watch(farmSizeRepositoryProvider)
        : null;
    final ageAsync =
        (_selectedMetric == MapMetric.starost ||
            _selectedMetric == MapMetric.mladji)
        ? ref.watch(ageRepositoryProvider)
        : null;

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (snapshots) {
        final activeByMunicipality = <String, int>{};
        if (snapshots.isNotEmpty) {
          final latest = snapshots.last;
          for (final r in latest.records) {
            final key =
                resolver?.canonicalKey(r.municipalityName) ??
                normaliseSerbianName(r.municipalityName);
            activeByMunicipality[key] =
                (activeByMunicipality[key] ?? 0) + r.activeHoldings;
          }
        }

        // Compute metric values for choropleth coloring
        final metricValues = <String, double>{};
        double maxValue = 0;
        bool secondaryLoading = false;

        if (_selectedMetric == MapMetric.gazdinstva) {
          for (final entry in activeByMunicipality.entries) {
            metricValues[entry.key] = entry.value.toDouble();
          }
          maxValue = metricValues.values.fold(0.0, (a, b) => a > b ? a : b);
        } else if (_selectedMetric == MapMetric.velicina) {
          secondaryLoading = farmSizeAsync?.isLoading ?? true;
          final farmSizeData = farmSizeAsync?.valueOrNull;
          if (farmSizeData != null && farmSizeData.isNotEmpty) {
            _computeFarmSizeMetric(farmSizeData.last, resolver, metricValues);
            maxValue = metricValues.values.fold(0.0, (a, b) => a > b ? a : b);
          }
        } else if (_selectedMetric == MapMetric.starost) {
          secondaryLoading = ageAsync?.isLoading ?? true;
          final ageData = ageAsync?.valueOrNull;
          if (ageData != null && ageData.isNotEmpty) {
            _computeAgeMetric(ageData.last, resolver, metricValues);
            maxValue = metricValues.values.fold(0.0, (a, b) => a > b ? a : b);
          }
        } else if (_selectedMetric == MapMetric.mladji) {
          secondaryLoading = ageAsync?.isLoading ?? true;
          final ageData = ageAsync?.valueOrNull;
          if (ageData != null && ageData.isNotEmpty) {
            _computeYoungPercentMetric(ageData.last, resolver, metricValues);
            maxValue = metricValues.values.fold(0.0, (a, b) => a > b ? a : b);
          }
        }

        return ScreenScaffold(
          title: 'Mapa',
          fullWidth: true,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: _serbiaBounds,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.serbiaOpenData.rpg',
                    tileProvider: widget.tileProvider,
                  ),
                  if (_geoJson != null)
                    PolygonLayer(
                      hitNotifier: _hitNotifier,
                      polygons: _buildPolygons(
                        metricValues,
                        maxValue,
                        secondaryLoading,
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _buildMetricSelector(context),
              ),
              if (secondaryLoading)
                const Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_tappedMunicipality != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop(context) ? 600 : double.infinity,
                      maxHeight:
                          MediaQuery.sizeOf(context).height * 0.4,
                    ),
                    child: _buildOverlay(
                      snapshots,
                      activeByMunicipality,
                      resolver,
                      farmSizeAsync,
                      ageAsync,
                    ),
                  ),
                ),
              Positioned(
                bottom: _tappedMunicipality != null
                    ? MediaQuery.sizeOf(context).height * 0.4 + 16
                    : 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'recenter',
                      onPressed: () => _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: _serbiaBounds,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricSelector(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SegmentedButton<MapMetric>(
          segments: [
            const ButtonSegment(
              value: MapMetric.gazdinstva,
              label: Text('Gazdinstva'),
            ),
            ButtonSegment(
              value: MapMetric.velicina,
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Veličina'),
                  Text('(ha)', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const ButtonSegment(
              value: MapMetric.starost,
              label: Text('Starost'),
            ),
            const ButtonSegment(
              value: MapMetric.mladji,
              label: Text('< 40 god.'),
            ),
          ],
          selected: {_selectedMetric},
          onSelectionChanged: (selected) => setState(() {
            _selectedMetric = selected.first;
          }),
        ),
      ),
    );
  }

  Widget _buildOverlay(
    List<Snapshot> snapshots,
    Map<String, int> activeByMunicipality,
    NameResolver? resolver,
    AsyncValue<List<FarmSizeSnapshot>>? farmSizeAsync,
    AsyncValue<List<AgeSnapshot>>? ageAsync,
  ) {
    if (_selectedMetric == MapMetric.gazdinstva) {
      return _MunicipalityOverlay(
        name: _tappedMunicipality!,
        records: snapshots.last.records,
        activeByMunicipality: activeByMunicipality,
        resolver: resolver,
        onClose: () => setState(() => _tappedMunicipality = null),
      );
    } else if (_selectedMetric == MapMetric.velicina) {
      return _FarmSizeOverlay(
        name: _tappedMunicipality!,
        farmSizeAsync: farmSizeAsync,
        resolver: resolver,
        onClose: () => setState(() => _tappedMunicipality = null),
      );
    } else {
      return _AgeOverlay(
        name: _tappedMunicipality!,
        ageAsync: ageAsync,
        metric: _selectedMetric,
        resolver: resolver,
        onClose: () => setState(() => _tappedMunicipality = null),
      );
    }
  }

  void _computeFarmSizeMetric(
    FarmSizeSnapshot snapshot,
    NameResolver? resolver,
    Map<String, double> out,
  ) {
    final totalFarms = <String, int>{};
    final totalArea = <String, double>{};
    for (final r in snapshot.records) {
      final key =
          resolver?.canonicalKey(r.municipalityName) ??
          normaliseSerbianName(r.municipalityName);
      totalFarms[key] = (totalFarms[key] ?? 0) + r.totalFarms;
      totalArea[key] = (totalArea[key] ?? 0) + r.totalArea;
    }
    for (final key in totalFarms.keys) {
      final farms = totalFarms[key]!;
      if (farms > 0) out[key] = totalArea[key]! / farms;
    }
  }

  void _computeAgeMetric(
    AgeSnapshot snapshot,
    NameResolver? resolver,
    Map<String, double> out,
  ) {
    final totalCount = <String, int>{};
    final weightedSum = <String, double>{};
    for (final r in snapshot.records) {
      final key =
          resolver?.canonicalKey(r.municipalityName) ??
          normaliseSerbianName(r.municipalityName);
      totalCount[key] = (totalCount[key] ?? 0) + r.farmCount;
      weightedSum[key] =
          (weightedSum[key] ?? 0) + r.farmCount * r.ageBracket.midpoint;
    }
    for (final key in totalCount.keys) {
      final count = totalCount[key]!;
      if (count > 0) out[key] = weightedSum[key]! / count;
    }
  }

  void _computeYoungPercentMetric(
    AgeSnapshot snapshot,
    NameResolver? resolver,
    Map<String, double> out,
  ) {
    final totalCount = <String, int>{};
    final youngCount = <String, int>{};
    for (final r in snapshot.records) {
      final key =
          resolver?.canonicalKey(r.municipalityName) ??
          normaliseSerbianName(r.municipalityName);
      totalCount[key] = (totalCount[key] ?? 0) + r.farmCount;
      if (r.ageBracket.index < AgeBracket.age40to49.index) {
        youngCount[key] = (youngCount[key] ?? 0) + r.farmCount;
      }
    }
    for (final key in totalCount.keys) {
      final total = totalCount[key]!;
      if (total > 0) out[key] = (youngCount[key] ?? 0) / total * 100;
    }
  }

  Color _baseColorLow(MapMetric metric) => switch (metric) {
    MapMetric.gazdinstva => Colors.green.shade100,
    MapMetric.velicina => Colors.blue.shade100,
    MapMetric.starost => Colors.orange.shade100,
    MapMetric.mladji => Colors.purple.shade100,
  };

  Color _baseColorHigh(MapMetric metric) => switch (metric) {
    MapMetric.gazdinstva => Colors.green.shade900,
    MapMetric.velicina => Colors.blue.shade900,
    MapMetric.starost => Colors.orange.shade900,
    MapMetric.mladji => Colors.purple.shade900,
  };

  List<Polygon> _buildPolygons(
    Map<String, double> metricValues,
    double maxValue,
    bool secondaryLoading,
  ) {
    final features = _geoJson!['features'] as List<dynamic>;
    final polygons = <Polygon>[];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final name = properties['NAME_2'] as String? ?? '';
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;

      final normalised = normaliseSerbianName(name);
      Color color;
      if (secondaryLoading) {
        color = Colors.grey.shade300;
      } else {
        final value = metricValues[normalised];
        color = value != null && maxValue > 0
            ? Color.lerp(
                _baseColorLow(_selectedMetric),
                _baseColorHigh(_selectedMetric),
                value / maxValue,
              )!
            : Colors.grey.shade300;
      }

      final rings = _extractRings(geometry, type);
      for (final ring in rings) {
        polygons.add(
          Polygon(
            points: ring,
            color: color.withValues(alpha: 0.6),
            borderColor: Colors.black45,
            borderStrokeWidth: 1,
            hitValue: name,
          ),
        );
      }
    }

    return polygons;
  }

  List<List<LatLng>> _extractRings(Map<String, dynamic> geometry, String type) {
    final coordinates = geometry['coordinates'];
    final rings = <List<LatLng>>[];

    if (type == 'Polygon') {
      for (final ring in coordinates as List) {
        rings.add(_toLatLngs(ring as List));
      }
    } else if (type == 'MultiPolygon') {
      for (final polygon in coordinates as List) {
        for (final ring in polygon as List) {
          rings.add(_toLatLngs(ring as List));
        }
      }
    }

    return rings;
  }

  List<LatLng> _toLatLngs(List<dynamic> coords) {
    return coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }
}

class _MunicipalityOverlay extends StatelessWidget {
  const _MunicipalityOverlay({
    required this.name,
    required this.records,
    required this.activeByMunicipality,
    required this.onClose,
    this.resolver,
  });

  final String name;
  final List<Record> records;
  final Map<String, int> activeByMunicipality;
  final VoidCallback onClose;
  final NameResolver? resolver;

  @override
  Widget build(BuildContext context) {
    final normalised = normaliseSerbianName(name);
    final totalActive = activeByMunicipality[normalised] ?? 0;

    final municipalityRecords = records.where((r) {
      final key =
          resolver?.canonicalKey(r.municipalityName) ??
          normaliseSerbianName(r.municipalityName);
      return key == normalised;
    }).toList();

    return _OverlayContainer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayName(name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalActive',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 8),
              Text(
                'Aktivnih gazdinstava',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (totalActive == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Podaci za ovu opštinu mogu biti objedinjeni sa drugom opštinom',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else if (municipalityRecords.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: municipalityRecords
                  .where((r) => r.activeHoldings > 0)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              r.orgForm.displayName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${r.activeHoldings}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}

class _OverlayContainer extends StatelessWidget {
  const _OverlayContainer({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FarmSizeOverlay extends StatelessWidget {
  const _FarmSizeOverlay({
    required this.name,
    required this.farmSizeAsync,
    required this.onClose,
    this.resolver,
  });

  final String name;
  final AsyncValue<List<FarmSizeSnapshot>>? farmSizeAsync;
  final VoidCallback onClose;
  final NameResolver? resolver;

  @override
  Widget build(BuildContext context) {
    final normalised = normaliseSerbianName(name);

    return _OverlayContainer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayName(name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
        ),
        if (farmSizeAsync == null || farmSizeAsync!.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (farmSizeAsync!.hasValue) ...[
          Builder(
            builder: (context) {
              final snapshots = farmSizeAsync!.value!;
              if (snapshots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nema podataka'),
                );
              }
              final latest = snapshots.last;
              final records = latest.records.where((r) {
                final key =
                    resolver?.canonicalKey(r.municipalityName) ??
                    normaliseSerbianName(r.municipalityName);
                return key == normalised;
              }).toList();

              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nema podataka o veličini za ovu opštinu',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }

              var totalFarms = 0;
              var totalArea = 0.0;
              var countUpTo5 = 0;
              var count5to20 = 0;
              var count20to100 = 0;
              var countOver100 = 0;
              for (final r in records) {
                totalFarms += r.totalFarms;
                totalArea += r.totalArea;
                countUpTo5 += r.countUpTo5;
                count5to20 += r.count5to20;
                count20to100 += r.count20to100;
                countOver100 += r.countOver100;
              }
              final avgSize = totalFarms > 0 ? totalArea / totalFarms : 0.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prosečna veličina: ${avgSize.toStringAsFixed(1).replaceAll('.', ',')} ha',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(),
                    _bracketRow(context, '≤5 ha', countUpTo5),
                    _bracketRow(context, '5–20 ha', count5to20),
                    _bracketRow(context, '20–100 ha', count20to100),
                    _bracketRow(context, '>100 ha', countOver100),
                  ],
                ),
              );
            },
          ),
        ] else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Greška pri učitavanju podataka',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _bracketRow(BuildContext context, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text('$count', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AgeOverlay extends StatelessWidget {
  const _AgeOverlay({
    required this.name,
    required this.ageAsync,
    required this.metric,
    required this.onClose,
    this.resolver,
  });

  final String name;
  final AsyncValue<List<AgeSnapshot>>? ageAsync;
  final MapMetric metric;
  final VoidCallback onClose;
  final NameResolver? resolver;

  @override
  Widget build(BuildContext context) {
    final normalised = normaliseSerbianName(name);

    return _OverlayContainer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayName(name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
        ),
        if (ageAsync == null || ageAsync!.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (ageAsync!.hasValue) ...[
          Builder(
            builder: (context) {
              final snapshots = ageAsync!.value!;
              if (snapshots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nema podataka'),
                );
              }
              final latest = snapshots.last;
              final records = latest.records.where((r) {
                final key =
                    resolver?.canonicalKey(r.municipalityName) ??
                    normaliseSerbianName(r.municipalityName);
                return key == normalised;
              }).toList();

              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nema podataka o starosti za ovu opštinu',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }

              var totalCount = 0;
              var weightedSum = 0.0;
              var youngCount = 0;
              final byBracket = <AgeBracket, int>{};
              for (final r in records) {
                totalCount += r.farmCount;
                weightedSum += r.farmCount * r.ageBracket.midpoint;
                byBracket[r.ageBracket] =
                    (byBracket[r.ageBracket] ?? 0) + r.farmCount;
                if (r.ageBracket.index < AgeBracket.age40to49.index) {
                  youngCount += r.farmCount;
                }
              }
              final avgAge = totalCount > 0 ? weightedSum / totalCount : 0.0;
              final youngPct = totalCount > 0
                  ? youngCount / totalCount * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metric == MapMetric.starost)
                      Text(
                        'Prosečna starost: ${avgAge.round()} god.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      )
                    else
                      Text(
                        'Nosioci < 40: ${youngPct.toStringAsFixed(1).replaceAll('.', ',')}%',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    if (metric == MapMetric.mladji)
                      Text(
                        '($youngCount od $totalCount)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const Divider(),
                    for (final entry
                        in (byBracket.entries.toList()
                          ..sort((a, b) => a.key.index.compareTo(b.key.index))))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.displayName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ] else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Greška pri učitavanju podataka',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
