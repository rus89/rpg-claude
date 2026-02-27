// ABOUTME: Mapa screen — choropleth map of Serbia coloured by active holdings per municipality.
// ABOUTME: Uses bundled GeoJSON and flutter_map; tapping a municipality shows an info card.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/data_provider.dart';

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  Map<String, dynamic>? _geoJson;
  String? _tappedMunicipality;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
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
            final key = _normalise(r.municipalityName);
            activeByMunicipality[key] =
                (activeByMunicipality[key] ?? 0) + r.activeHoldings;
          }
          maxValue = activeByMunicipality.values.fold(
            0,
            (a, b) => a > b ? a : b,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Mapa')),
          body: Stack(
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
                  ),
                  if (_geoJson != null)
                    PolygonLayer(
                      polygons: _buildPolygons(activeByMunicipality, maxValue),
                    ),
                ],
              ),
              if (_tappedMunicipality != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _tappedMunicipality!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${activeByMunicipality[_normalise(_tappedMunicipality!)] ?? 0} aktivnih',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _tappedMunicipality = null),
                          ),
                        ],
                      ),
                    ),
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

      final normalised = _normalise(name);
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

  String _normalise(String name) {
    return name
        .toLowerCase()
        .replaceAll('š', 's')
        .replaceAll('đ', 'dj')
        .replaceAll('č', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('ž', 'z')
        .trim();
  }
}
