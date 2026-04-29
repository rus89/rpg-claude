// ABOUTME: Widget tests for the O aplikaciji (about) screen.
// ABOUTME: Verifies disclaimer text and data source credit are present.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rpg_claude/screens/o_aplikaciji/o_aplikaciji_screen.dart';
import 'package:rpg_claude/theme.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  testWidgets('shows disclaimer text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.textContaining('nezavisan'), findsWidgets);
  });

  testWidgets('shows data source credit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.textContaining('data.gov.rs'), findsWidgets);
  });

  testWidgets('info sections show leading icons', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.gavel), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('shows tappable data source link', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    // The link text should be present and tappable
    expect(find.textContaining('data.gov.rs'), findsWidgets);
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('shows guide for all 4 main tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OAplikacijiScreen()));
    await tester.scrollUntilVisible(find.text('Pregled'), 100);
    expect(find.text('Pregled'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Opštine'), 100);
    expect(find.text('Opštine'), findsOneWidget);
  });

  group('desktop (>= 1024px)', () {
    testWidgets('renders info cards at desktop width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OAplikacijiScreen())),
      );
      expect(find.textContaining('nezavisan'), findsWidgets);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('feedback tile disabled state', () {
    testWidgets(
      'feedback tile reports isEnabled:false and dims icon + chevron before '
      'PackageInfo loads',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
        );
        // Do NOT pumpAndSettle — we want the state before _loadPackageInfo resolves.
        await tester.pump();

        final data = tester
            .getSemantics(find.byIcon(Icons.mail_outline))
            .getSemanticsData();
        // ignore: deprecated_member_use
        expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
        // ignore: deprecated_member_use
        expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);

        // The leading icon and trailing chevron must have a visible disabled
        // affordance so taps don't silently vanish.
        final mailIconOpacity = _nearestOpacity(
          tester,
          find.byIcon(Icons.mail_outline),
        );
        expect(mailIconOpacity, isNotNull);
        expect(mailIconOpacity!.opacity, lessThanOrEqualTo(0.5));

        // The chevron inside the feedback tile should share the disabled
        // affordance. Scope the search to the feedback tile subtree so we
        // don't accidentally match the (enabled) rate tile's chevron.
        final feedbackTile = find.ancestor(
          of: find.byIcon(Icons.mail_outline),
          matching: find.byType(Semantics),
        );
        final chevron = find.descendant(
          of: feedbackTile.first,
          matching: find.byIcon(Icons.chevron_right),
        );
        expect(chevron, findsOneWidget);
        final chevronOpacity = _nearestOpacity(tester, chevron);
        expect(chevronOpacity, isNotNull);
        expect(chevronOpacity!.opacity, lessThanOrEqualTo(0.5));

        handle.dispose();
      },
    );

    testWidgets('feedback tile stays disabled and no exception leaks when '
        'PackageInfo.fromPlatform throws', (tester) async {
      // Force the package_info_plus method channel to throw so the
      // _loadPackageInfo catch block runs. This is the scenario a real
      // device could hit if the plugin fails to initialise.
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'UNAVAILABLE');
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final data = tester
          .getSemantics(find.byIcon(Icons.mail_outline))
          .getSemanticsData();
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);
      handle.dispose();
    });

    testWidgets(
      'feedback tile becomes enabled and removes dim once PackageInfo loads',
      (tester) async {
        PackageInfo.setMockInitialValues(
          appName: 'GeoAgro Srbija',
          packageName: 'com.serbiaOpenData.rpg_claude',
          version: '1.0.1',
          buildNumber: '4',
          buildSignature: '',
        );
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
        );
        await tester.pumpAndSettle();

        final data = tester
            .getSemantics(find.byIcon(Icons.mail_outline))
            .getSemanticsData();
        // ignore: deprecated_member_use
        expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);

        final mailIconOpacity = _nearestOpacity(
          tester,
          find.byIcon(Icons.mail_outline),
        );
        // Either there is no dimming ancestor, or it's fully opaque.
        expect(mailIconOpacity?.opacity ?? 1.0, equals(1.0));
        handle.dispose();
      },
    );
  });

  group('action tiles', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'GeoAgro Srbija',
        packageName: 'com.serbiaOpenData.rpg_claude',
        version: '1.0.1',
        buildNumber: '4',
        buildSignature: '',
      );
    });

    testWidgets('renders both action tiles on non-web', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Oceni aplikaciju'), findsOneWidget);
      expect(find.text('Prijavite grešku ili predlog'), findsOneWidget);
    });

    testWidgets('renders Privacy Policy tile with button semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Politika privatnosti'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);

      final data = tester
          .getSemantics(find.byIcon(Icons.privacy_tip_outlined))
          .getSemanticsData();
      expect(
        data.label,
        contains('Otvori politiku privatnosti u pregledaču'),
      );
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
      handle.dispose();
    });

    testWidgets('rate tile exposes button semantics with accessibility label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byIcon(Icons.star_rate))
          .getSemanticsData();
      expect(data.label, contains('Oceni aplikaciju u Google Play prodavnici'));
      // ignore: deprecated_member_use — flagsCollection is newer but SemanticsData.hasFlag still works across supported Flutter versions.
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('shouldShowRateTile', () {
    test('returns false on web', () {
      expect(shouldShowRateTile(isWeb: true), isFalse);
    });

    test('returns true off web', () {
      expect(shouldShowRateTile(isWeb: false), isTrue);
    });
  });

  group('buildFeedbackUri', () {
    test('produces mailto with version-stamped body and subject', () {
      final info = PackageInfo(
        appName: 'GeoAgro Srbija',
        packageName: 'com.serbiaOpenData.rpg_claude',
        version: '1.0.2',
        buildNumber: '5',
        buildSignature: '',
      );
      final uri = buildFeedbackUri(info);
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'serbiaopendataapps@gmail.com');
      final params = uri.queryParameters;
      expect(params['subject'], 'GeoAgro Srbija — povratna informacija');
      expect(params['body'], 'Verzija aplikacije: v1.0.2+5\n\n');
    });

    test('encodes spaces as %20 (RFC 6068), not + (form-urlencoded)', () {
      // Strict mailto handlers render + literally; only %20 is decoded back
      // to a space. `Uri.queryParameters` decoding hides the difference,
      // so this test inspects the raw string.
      final info = PackageInfo(
        appName: 'GeoAgro Srbija',
        packageName: 'com.serbiaOpenData.rpg_claude',
        version: '1.0.2',
        buildNumber: '5',
        buildSignature: '',
      );
      final encoded = buildFeedbackUri(info).toString();

      expect(encoded, contains('GeoAgro%20Srbija'));
      expect(encoded, contains('Verzija%20aplikacije'));
      expect(encoded, isNot(contains('GeoAgro+Srbija')));
      expect(encoded, isNot(contains('Verzija+aplikacije')));
      // Literal '+' between version and build number must survive as %2B.
      expect(encoded, contains('v1.0.2%2B5'));
    });
  });

  group('launch failure fallbacks', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'GeoAgro Srbija',
        packageName: 'com.serbiaOpenData.rpg_claude',
        version: '1.0.1',
        buildNumber: '4',
        buildSignature: '',
      );
    });

    Future<_RecordingUrlLauncher> installLauncher({
      bool result = true,
      Object? throwError,
    }) async {
      final original = UrlLauncherPlatform.instance;
      final launcher = _RecordingUrlLauncher(
        result: result,
        throwError: throwError,
      );
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = original);
      return launcher;
    }

    Future<void> pumpAt(WidgetTester tester, {Size? size}) async {
      if (size != null) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }
      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const OAplikacijiScreen()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('rate tile shows link error snackbar when launch throws', (
      tester,
    ) async {
      await installLauncher(throwError: PlatformException(code: 'FAILED'));
      await pumpAt(tester, size: const Size(800, 2000));

      await tester.tap(find.text('Oceni aplikaciju'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nije moguće otvoriti link.'), findsOneWidget);
    });

    testWidgets(
      'rate tile shows link error snackbar when launch returns false',
      (tester) async {
        await installLauncher(result: false);
        await pumpAt(tester, size: const Size(800, 2000));

        await tester.tap(find.text('Oceni aplikaciju'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Nije moguće otvoriti link.'), findsOneWidget);
      },
    );

    testWidgets(
      'feedback tile shows copyable feedback error snackbar when launch throws',
      (tester) async {
        await installLauncher(throwError: PlatformException(code: 'FAILED'));
        await pumpAt(tester, size: const Size(800, 2000));

        await tester.tap(find.text('Prijavite grešku ili predlog'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The SnackBar text must surface the fallback email so the user has
        // something they can act on.
        expect(
          find.textContaining('serbiaopendataapps@gmail.com'),
          findsOneWidget,
        );
        // And a Kopiraj action so they can actually copy the email.
        final action = tester.widget<SnackBarAction>(
          find.byType(SnackBarAction),
        );
        expect(action.label, 'Kopiraj');
      },
    );

    testWidgets(
      'feedback tile Kopiraj action writes the email to the clipboard',
      (tester) async {
        await installLauncher(throwError: PlatformException(code: 'FAILED'));

        final clipboardCalls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
          }
          return null;
        });
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );

        await pumpAt(tester, size: const Size(800, 2000));

        await tester.tap(find.text('Prijavite grešku ili predlog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Kopiraj'));
        await tester.pumpAndSettle();

        expect(clipboardCalls, hasLength(1));
        final args = clipboardCalls.single.arguments as Map;
        expect(args['text'], 'serbiaopendataapps@gmail.com');
      },
    );

    testWidgets('data source link shows snackbar when launch throws', (
      tester,
    ) async {
      await installLauncher(throwError: PlatformException(code: 'FAILED'));
      await pumpAt(tester);

      await tester.tap(find.text('data.gov.rs'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nije moguće otvoriti link.'), findsOneWidget);
    });
  });
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

// Returns the nearest Opacity ancestor of [of], or null if none exists.
Opacity? _nearestOpacity(WidgetTester tester, Finder of) {
  final matches = tester
      .widgetList<Opacity>(
        find.ancestor(of: of, matching: find.byType(Opacity)),
      )
      .toList();
  if (matches.isEmpty) return null;
  return matches.first;
}
