// ABOUTME: List of all age structure CSV snapshot URLs with their data dates.
// ABOUTME: Source dataset: "RPG broj nosilaca aktivnih gazdinstava prema starosnoj strukturi".

import 'data_source.dart';

class AgeSource {
  // static final instead of static const: DateTime has no const constructor.
  static final List<CsvSource> sources = [
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20180528-151440/Srbija_broj_gazinstava_po_opstinama_prema_opsegu_godina_05_28.csv',
      date: DateTime(2018, 5, 28),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20180815-082823/Srbija_broj_gazinstava_po_opstinama_prema_opsegu_godina_08_15.csv',
      date: DateTime(2018, 8, 15),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20190717-093012/srbija-broj-gazinstava-po-opstinama-prema-opsegu-godina-07-17-2019.csv',
      date: DateTime(2019, 7, 17),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20200615-125557/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-06-15-2020.csv',
      date: DateTime(2020, 6, 15),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20210610-095103/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-06-10-2021.csv',
      date: DateTime(2021, 6, 10),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20211201-134534/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-01-12-2021.csv',
      date: DateTime(2021, 12, 1),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20220928-121547/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-28-09-2022.csv',
      date: DateTime(2022, 9, 28),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20241025-085950/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-25-10-2024.csv',
      date: DateTime(2024, 10, 25),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20250109-092421/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-31-12-2024.csv',
      date: DateTime(2024, 12, 31),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20250707-085436/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-07-07-2025.csv',
      date: DateTime(2025, 7, 7),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20260108-073012/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-31-12-2025.csv',
      date: DateTime(2025, 12, 31),
    ),
  ];
}
