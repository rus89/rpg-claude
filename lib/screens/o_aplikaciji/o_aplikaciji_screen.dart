// ABOUTME: O aplikaciji screen — static content with disclaimer and per-screen guide.
// ABOUTME: Explains data source and independence from government bodies.

import 'package:flutter/material.dart';

class OAplikacijiScreen extends StatelessWidget {
  const OAplikacijiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O aplikaciji')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'O aplikaciji',
              body:
                  'Ova aplikacija prikazuje otvorene podatke o registrovanim '
                  'poljoprivrednim gazdinstvima u Srbiji (RPG), preuzete sa portala '
                  'data.gov.rs. Cilj aplikacije je obrazovni — da omogući svim '
                  'zainteresovanim građanima lak pristup ovim podacima.',
            ),
            Divider(height: 32),
            _Section(
              title: 'Napomena o nezavisnosti',
              body:
                  'Ova aplikacija je razvio nezavisan developer i nije '
                  'povezana ni sa jednim državnim organom, institucijom ili '
                  'organizacijom. Podaci se preuzimaju direktno sa portala '
                  'data.gov.rs i koriste se isključivo u informativne i '
                  'obrazovne svrhe.',
            ),
            Divider(height: 32),
            _Section(
              title: 'Izvor podataka',
              body:
                  'Podaci potiču od Uprave za agrarna plaćanja i dostupni '
                  'su na: data.gov.rs',
            ),
            Divider(height: 32),
            Text(
              'Vodič kroz aplikaciju',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _TabGuide(
              tabName: 'Pregled',
              description:
                  'Prikazuje ukupan broj registrovanih i aktivnih gazdinstava '
                  'na nivou Srbije za najnoviji dostupni snimak podataka, kao i '
                  'raspodelu po obliku organizacije.',
            ),
            _TabGuide(
              tabName: 'Opštine',
              description:
                  'Pretraži sve opštine i pogledaj detalje za svaku — '
                  'aktivan broj gazdinstava po obliku organizacije i trend kroz vreme.',
            ),
            _TabGuide(
              tabName: 'Trendovi',
              description:
                  'Prati kako se broj aktivnih gazdinstava menjao od 2018. '
                  'do danas. Filtriraj po opštini i obliku organizacije, ili '
                  'poređaj više opština na istom grafikonu.',
            ),
            _TabGuide(
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(body),
      ],
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
          Text(tabName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}
