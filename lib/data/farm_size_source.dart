// ABOUTME: List of all farm size distribution CSV snapshot URLs with their data dates.
// ABOUTME: Source dataset: "Veličina PG poljoprivrednih gazdinstava u Republici Srbiji".

import 'data_source.dart';

class FarmSizeSource {
  // static final instead of static const: DateTime has no const constructor.
  static final List<CsvSource> sources = [
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20180226-130942/Srbija_broj_gazinstava_po_opstinama_prema_velicini_gazdinstva.csv',
      date: DateTime(2018, 2, 26),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20180528-094517/Srbija_broj_gazinstava_po_opstinama_prema_velicini_gadinstva_05_28.csv',
      date: DateTime(2018, 5, 28),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20190717-093529/srbija-broj-gazinstava-po-opstinama-prema-velicini-gazdinstva-07-17-2019.csv',
      date: DateTime(2019, 7, 17),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20200615-125802/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-06-15-2020.csv',
      date: DateTime(2020, 6, 15),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20210610-095552/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-06-10-2021.csv',
      date: DateTime(2021, 6, 10),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20211201-134725/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-01-12-2021.csv',
      date: DateTime(2021, 12, 1),
    ),
    // 2022-09-28 skipped — duplicate of 2021-12-01
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20241025-091520/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-25-10-2024.csv',
      date: DateTime(2024, 10, 25),
    ),
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20250109-092359/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-31-12-2024.csv',
      date: DateTime(2024, 12, 31),
    ),
    // 2025-07-07 skipped — XLSX format
    CsvSource(
      url:
          'https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20260108-073041/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-31-12-2025.csv',
      date: DateTime(2025, 12, 31),
    ),
  ];
}
