// ABOUTME: O aplikaciji screen — static content with disclaimer and per-screen guide.
// ABOUTME: Explains data source and independence from government bodies.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/breakpoints.dart';
import '../../layout/screen_scaffold.dart';
import '../../theme.dart';

class OAplikacijiScreen extends StatelessWidget {
  const OAplikacijiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);

    const infoCards = [
      _InfoCard(
        icon: Icons.info_outline,
        title: 'O aplikaciji',
        body: 'Ova aplikacija prikazuje otvorene podatke o registrovanim '
            'poljoprivrednim gazdinstvima u Srbiji (RPG), preuzete sa portala '
            'data.gov.rs. Cilj aplikacije je obrazovni — da omogući svim '
            'zainteresovanim građanima lak pristup ovim podacima.',
      ),
      _InfoCard(
        icon: Icons.gavel,
        title: 'Napomena o nezavisnosti',
        body: 'Ova aplikacija je razvio nezavisan developer i nije '
            'povezana ni sa jednim državnim organom, institucijom ili '
            'organizacijom. Podaci se preuzimaju direktno sa portala '
            'data.gov.rs i koriste se isključivo u informativne i '
            'obrazovne svrhe.',
      ),
      _InfoCard(
        icon: Icons.open_in_new,
        title: 'Izvor podataka',
        body: 'Podaci potiču od Uprave za agrarna plaćanja i dostupni '
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
            if (desktop)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: infoCards
                    .map(
                      (card) => SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 80) / 2,
                        child: card,
                      ),
                    )
                    .toList(),
              )
            else
              ...infoCards.expand(
                (card) => [card, const SizedBox(height: 12)],
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

const _dataSourceUrl =
    'https://data.gov.rs/sr/datasets/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/';

class _DataSourceLink extends StatelessWidget {
  const _DataSourceLink();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(_dataSourceUrl)),
      child: Text(
        'data.gov.rs',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
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
