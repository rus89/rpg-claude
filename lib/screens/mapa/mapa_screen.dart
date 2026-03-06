// ABOUTME: Mapa screen — choropleth map of Serbia coloured by active holdings per municipality.
// ABOUTME: Uses bundled GeoJSON and flutter_map; tapping a municipality shows an info card.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/record.dart';
import '../../data/name_resolver.dart';
import '../../data/serbian_normalise.dart';
import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../providers/data_provider.dart';

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key, this.tileProvider, this.hitNotifier});

  final TileProvider? tileProvider;
  final LayerHitNotifier<Object>? hitNotifier;

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  Map<String, dynamic>? _geoJson;
  String? _tappedMunicipality;
  late final LayerHitNotifier<Object> _hitNotifier;
  late final bool _ownsNotifier;

  @override
  void initState() {
    super.initState();
    _ownsNotifier = widget.hitNotifier == null;
    _hitNotifier = widget.hitNotifier ?? ValueNotifier(null);
    _loadGeoJson();
    _hitNotifier.addListener(_onPolygonHit);
  }

  @override
  void dispose() {
    _hitNotifier.removeListener(_onPolygonHit);
    if (_ownsNotifier) _hitNotifier.dispose();
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

    return dataAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Greška: $e'))),
      data: (snapshots) {
        final activeByMunicipality = <String, int>{};
        int maxValue = 0;
        if (snapshots.isNotEmpty) {
          final latest = snapshots.last;
          for (final r in latest.records) {
            final key =
                resolver?.canonicalKey(r.municipalityName) ??
                normaliseSerbianName(r.municipalityName);
            activeByMunicipality[key] =
                (activeByMunicipality[key] ?? 0) + r.activeHoldings;
          }
          maxValue = activeByMunicipality.values.fold(
            0,
            (a, b) => a > b ? a : b,
          );
        }

        return ScreenScaffold(
          title: 'Mapa',
          fullWidth: true,
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(44.0, 21.0),
                  initialZoom: 7.0,
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
                      polygons: _buildPolygons(activeByMunicipality, maxValue),
                    ),
                ],
              ),
              if (_tappedMunicipality != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: isDesktop(context)
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _MunicipalityOverlay(
                              name: _tappedMunicipality!,
                              records: snapshots.last.records,
                              activeByMunicipality: activeByMunicipality,
                              resolver: resolver,
                              onClose: () =>
                                  setState(() => _tappedMunicipality = null),
                            ),
                          ),
                        )
                      : _MunicipalityOverlay(
                          name: _tappedMunicipality!,
                          records: snapshots.last.records,
                          activeByMunicipality: activeByMunicipality,
                          resolver: resolver,
                          onClose: () =>
                              setState(() => _tappedMunicipality = null),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Polygon> _buildPolygons(
    Map<String, int> activeByMunicipality,
    int maxValue,
  ) {
    final features = _geoJson!['features'] as List<dynamic>;
    final polygons = <Polygon>[];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final name = properties['NAME_2'] as String? ?? '';
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;

      final normalised = normaliseSerbianName(name);
      final count = activeByMunicipality[normalised];
      final color = count != null && maxValue > 0
          ? Color.lerp(
              Colors.green.shade100,
              Colors.green.shade900,
              count / maxValue,
            )!
          : Colors.grey.shade300;

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
      ),
    );
  }
}
