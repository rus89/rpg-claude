// ABOUTME: O aplikaciji screen — static content with disclaimer and per-screen guide.
// ABOUTME: Explains data source and independence from government bodies.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../theme.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.serbiaOpenData.rpg_claude';
const _feedbackEmail = 'serbiaopendataapps@gmail.com';
const _feedbackSubject = 'GeoAgro Srbija — povratna informacija';
const _linkErrorMessage = 'Nije moguće otvoriti link.';
const _feedbackErrorMessage =
    'Nije moguće otvoriti mail klijent. Pošaljite poruku na $_feedbackEmail';
const _privacyPolicyUrl = 'https://sites.google.com/view/serbiaopendata/home';

class OAplikacijiScreen extends StatefulWidget {
  const OAplikacijiScreen({super.key});

  @override
  State<OAplikacijiScreen> createState() => _OAplikacijiScreenState();
}

class _OAplikacijiScreenState extends State<OAplikacijiScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {
      // PackageInfo unavailable (e.g., test without mock). Feedback tile
      // stays disabled rather than firing a half-formed mailto.
    }
  }

  Future<void> _openRate() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_playStoreUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showSnack(_linkErrorMessage);
    } on PlatformException catch (_) {
      if (mounted) _showSnack(_linkErrorMessage);
    }
  }

  Future<void> _openFeedback() async {
    final info = _packageInfo;
    if (info == null) return;
    try {
      final opened = await launchUrl(
        buildFeedbackUri(info),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showFeedbackFallback();
    } on PlatformException catch (_) {
      if (mounted) _showFeedbackFallback();
    }
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final opened = await launchUrl(
        Uri.parse(_privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showSnack(_linkErrorMessage);
    } on PlatformException catch (_) {
      if (mounted) _showSnack(_linkErrorMessage);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFeedbackFallback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(_feedbackErrorMessage),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Kopiraj',
          onPressed: () =>
              Clipboard.setData(const ClipboardData(text: _feedbackEmail)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final showRate = shouldShowRateTile();
    final feedbackReady = _packageInfo != null;

    const infoCards = [
      _InfoCard(
        icon: Icons.info_outline,
        title: 'O aplikaciji',
        body:
            'Ova aplikacija prikazuje otvorene podatke o registrovanim '
            'poljoprivrednim gazdinstvima u Srbiji (RPG), preuzete sa portala '
            'data.gov.rs. Cilj aplikacije je obrazovni — da omogući svim '
            'zainteresovanim građanima lak pristup ovim podacima.',
      ),
      _InfoCard(
        icon: Icons.gavel,
        title: 'Napomena o nezavisnosti',
        body:
            'Ova aplikacija je razvio nezavisan developer i nije '
            'povezana ni sa jednim državnim organom, institucijom ili '
            'organizacijom. Podaci se preuzimaju direktno sa portala '
            'data.gov.rs i koriste se isključivo u informativne i '
            'obrazovne svrhe.',
      ),
      _InfoCard(
        icon: Icons.open_in_new,
        title: 'Izvor podataka',
        body:
            'Podaci potiču od Uprave za agrarna plaćanja i dostupni '
            'su na:',
        link: _DataSourceLink(),
      ),
    ];

    return ScreenScaffold(
      title: 'O aplikaciji',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desktop) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: infoCards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: infoCards[1]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              infoCards[2],
            ] else
              ...infoCards.expand((card) => [card, const SizedBox(height: 12)]),
            const SizedBox(height: 24),
            if (showRate) ...[
              _ActionCard(
                icon: Icons.star_rate,
                title: 'Oceni aplikaciju',
                subtitle: 'Otvori Google Play prodavnicu',
                semanticsLabel: 'Oceni aplikaciju u Google Play prodavnici',
                onTap: _openRate,
              ),
              const SizedBox(height: 12),
            ],
            _ActionCard(
              icon: Icons.mail_outline,
              title: 'Prijavite grešku ili predlog',
              subtitle: 'Pošaljite poruku autoru',
              semanticsLabel: 'Prijavite grešku ili predlog autoru aplikacije',
              onTap: feedbackReady ? _openFeedback : null,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Politika privatnosti',
              subtitle: 'Pogledaj kako koristimo podatke',
              semanticsLabel: 'Otvori politiku privatnosti u pregledaču',
              onTap: _openPrivacyPolicy,
            ),
            const SizedBox(height: 24),
            Text(
              'Vodič kroz aplikaciju',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const _TabGuide(
              tabName: 'Pregled',
              description:
                  'Prikazuje ukupan broj registrovanih i aktivnih gazdinstava '
                  'na nivou Srbije za najnoviji dostupni snimak podataka, kao i '
                  'raspodelu po obliku organizacije.',
            ),
            const _TabGuide(
              tabName: 'Opštine',
              description:
                  'Pretraži sve opštine i pogledaj detalje za svaku — '
                  'aktivan broj gazdinstava po obliku organizacije i trend kroz vreme.',
            ),
            const _TabGuide(
              tabName: 'Trendovi',
              description:
                  'Prati kako se broj aktivnih gazdinstava menjao od 2018. '
                  'do danas. Filtriraj po opštini i obliku organizacije, ili '
                  'poređaj više opština na istom grafikonu.',
            ),
            const _TabGuide(
              tabName: 'Mapa',
              description:
                  'Geografski prikaz Srbije — opštine su obojene prema broju '
                  'aktivnih gazdinstava. Dodirnite opštinu za kratki pregled.',
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
bool shouldShowRateTile({bool isWeb = kIsWeb}) => !isWeb;

@visibleForTesting
Uri buildFeedbackUri(PackageInfo info) {
  // Encode per RFC 6068 (spaces as %20). Uri.queryParameters would encode
  // spaces as '+' (form-urlencoded), which strict mailto handlers render
  // literally instead of treating as space.
  final body = 'Verzija aplikacije: v${info.version}+${info.buildNumber}\n\n';
  return Uri.parse(
    'mailto:$_feedbackEmail'
    '?subject=${Uri.encodeComponent(_feedbackSubject)}'
    '&body=${Uri.encodeComponent(body)}',
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.link,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? link;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                  if (link != null) ...[const SizedBox(height: 4), link!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final disabled = onTap == null;
    return Semantics(
      container: true,
      button: true,
      enabled: !disabled,
      label: semanticsLabel,
      onTap: onTap,
      child: DecoratedBox(
        decoration: cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Opacity(
                    opacity: disabled ? 0.5 : 1.0,
                    child: Icon(icon, color: primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: disabled ? 0.5 : 1.0,
                    child: Icon(Icons.chevron_right, color: primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _dataSourceUrl =
    'https://data.gov.rs/sr/datasets/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/';

class _DataSourceLink extends StatelessWidget {
  const _DataSourceLink();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDataSource(context),
      child: Text(
        'data.gov.rs',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _openDataSource(BuildContext context) async {
    try {
      final opened = await launchUrl(
        Uri.parse(_dataSourceUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(_linkErrorMessage)));
      }
    } on PlatformException catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(_linkErrorMessage)));
    }
  }
}

class _TabGuide extends StatelessWidget {
  const _TabGuide({required this.tabName, required this.description});
  final String tabName;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tabName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}
