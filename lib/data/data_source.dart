// ABOUTME: Hardcoded list of all RPG CSV snapshot URLs with their data dates.
// ABOUTME: Exposes a fetch method that returns raw bytes for a given URL.

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'fetch_error.dart';

class CsvSource {
  const CsvSource({required this.url, required this.date});
  final String url;
  final DateTime date;
}

class DataSource {
  // static final instead of static const: DateTime has no const constructor.
  static final List<CsvSource> sources = [
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20180226-130228/Srbija_broj_gazinstava_po_opstinama_prema_organizacionom_obliku.csv',
      date: DateTime(2018, 2, 26),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20180528-090355/Srbija_broj_gazinstava_po_opstinama_prema_organizacionom_obliku_05_28.csv',
      date: DateTime(2018, 5, 28),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20180815-081910/Srbija_broj_gazinstava_po_opstinama_organizacionom_obliku_08_15.csv',
      date: DateTime(2018, 8, 15),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20190717-093917/srbija-broj-gazinstava-po-opstinama-organizacionom-obliku-07-17-2019.csv',
      date: DateTime(2019, 7, 17),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20200615-130128/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-06-15-2020.csv',
      date: DateTime(2020, 6, 15),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20210610-095742/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-06-10-2021.csv',
      date: DateTime(2021, 6, 10),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20211201-134751/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-01-12-2021.csv',
      date: DateTime(2021, 12, 1),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20220928-111852/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-28-09-2022.csv',
      date: DateTime(2022, 9, 28),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20241025-085857/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-25-10-2024.csv',
      date: DateTime(2024, 10, 25),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20250121-104213/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-31-12-2024.csv',
      date: DateTime(2024, 12, 31),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20250707-085335/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-07-07-2025.csv',
      date: DateTime(2025, 7, 7),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-svikh-registrovanikh-poljoprivrednikh-gazdinstava-aktivna-gazdinstva/20260108-073108/srbija-broj-gazdinstava-po-opshtinama-prema-organizatsionom-obliku-31-12-2025.csv',
      date: DateTime(2025, 12, 31),
    ),
  ];

  // Fetches raw bytes for a single CSV URL.
  // Throws FetchException with a classified FetchError on failure.
  static Future<List<int>> fetchBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        throw FetchException(FetchError.fromStatusCode(response.statusCode));
      }
      return response.bodyBytes;
    } on FetchException {
      rethrow;
    } on TimeoutException {
      throw const FetchException(FetchError.timeout);
    } on SocketException {
      throw const FetchException(FetchError.noInternet);
    } on Exception {
      throw const FetchException(FetchError.unknown);
    }
  }
}
