// ABOUTME: Widget test verifying the Mapa screen shows an always-visible OSM
// ABOUTME: tile attribution link that launches the OSM copyright URL on tap.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rpg_claude/data/models/org_form.dart';
import 'package:rpg_claude/data/models/record.dart';
import 'package:rpg_claude/data/models/snapshot.dart';
import 'package:rpg_claude/data/name_resolver.dart';
import 'package:rpg_claude/providers/data_provider.dart';
import 'package:rpg_claude/screens/mapa/mapa_screen.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

final _resolver = NameResolver(['Barajevo']);
const _attributionText = '© OpenStreetMap contributors';
const _semanticsLabel =
    'OpenStreetMap contributors — otvara openstreetmap.org u pregledaču';
const _osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMapa(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWith(() => _Fixture()),
          nameResolverProvider.overrideWith((ref) async => _resolver),
        ],
        child: MaterialApp(home: MapaScreen(tileProvider: _NoOpTileProvider())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows OSM attribution text visibly without interaction', (
    tester,
  ) async {
    await pumpMapa(tester);

    final textFinder = find.text(_attributionText);
    expect(textFinder, findsOneWidget);

    // Attribution must be on-screen without any user interaction.
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final rect = tester.getRect(textFinder);
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(size.height));
    expect(rect.right, lessThanOrEqualTo(size.width));

    // No ancestor should hide the text via Offstage or zero opacity.
    final offstage = tester.widgetList<Offstage>(
      find.ancestor(of: textFinder, matching: find.byType(Offstage)),
    );
    for (final widget in offstage) {
      expect(widget.offstage, isFalse);
    }
    final opacities = tester.widgetList<Opacity>(
      find.ancestor(of: textFinder, matching: find.byType(Opacity)),
    );
    for (final opacity in opacities) {
      expect(opacity.opacity, greaterThan(0));
    }
  });

  testWidgets('exposes the attribution as a link to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMapa(tester);

    final linkNode = tester.getSemantics(
      find
          .ancestor(
            of: find.text(_attributionText),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(linkNode, matchesSemantics(isLink: true, label: _semanticsLabel));

    handle.dispose();
  });

  testWidgets('attribution tap target is at least 48x48 dp', (tester) async {
    await pumpMapa(tester);

    final tapTarget = find.ancestor(
      of: find.text(_attributionText),
      matching: find.byType(InkWell),
    );
    expect(tapTarget, findsOneWidget);

    final size = tester.getSize(tapTarget);
    expect(size.width, greaterThanOrEqualTo(48.0));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('tapping the attribution launches the OSM copyright URL', (
    tester,
  ) async {
    final original = UrlLauncherPlatform.instance;
    final launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = original);

    await pumpMapa(tester);

    await tester.tap(find.text(_attributionText));
    await tester.pumpAndSettle();

    expect(launcher.launched, isNotEmpty);
    expect(launcher.launched.single, _osmCopyrightUrl);
  });

  testWidgets('tapping the attribution does not throw when launch fails', (
    tester,
  ) async {
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _RecordingUrlLauncher(result: false);
    addTearDown(() => UrlLauncherPlatform.instance = original);

    await pumpMapa(tester);

    await tester.tap(find.text(_attributionText));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nije moguće otvoriti link.'), findsOneWidget);
  });

  testWidgets('tapping the attribution shows a snackbar when launch throws', (
    tester,
  ) async {
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _RecordingUrlLauncher(
      throwError: PlatformException(code: 'FAILED'),
    );
    addTearDown(() => UrlLauncherPlatform.instance = original);

    await pumpMapa(tester);

    await tester.tap(find.text(_attributionText));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nije moguće otvoriti link.'), findsOneWidget);
  });
}

// Returns a transparent 1x1 PNG without making network requests.
class _NoOpTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}

class _Fixture extends DataRepository {
  @override
  Future<List<Snapshot>> build() async => [
    Snapshot(
      date: DateTime(2025, 12, 31),
      records: const [
        Record(
          regionCode: '1',
          regionName: 'R',
          municipalityCode: '10',
          municipalityName: 'Barajevo',
          orgForm: OrgForm.familyFarm,
          totalRegistered: 100,
          activeHoldings: 90,
        ),
      ],
    ),
  ];
}

// Records launchUrl calls so tests can verify the exact URL is passed.
class _RecordingUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _RecordingUrlLauncher({this.result = true, this.throwError});

  final bool result;
  final Object? throwError;
  final List<String> launched = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    if (throwError != null) throw throwError!;
    return result;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}
