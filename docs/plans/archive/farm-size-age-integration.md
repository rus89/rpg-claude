# Plan: Integrate Farm Size + Age Structure Datasets

## Context

The app currently shows RPG data (registered farm counts by municipality × org form). Two additional datasets from the same publisher ("Uprava za agrarna plaćanja") are available on data.gov.rs:

1. **Farm Size Distribution** — per municipality, farms categorized by land area (≤5ha, 5-20ha, 20-100ha, >100ha) with counts and total area
2. **Age Structure** — per municipality, farm operator counts by 10-year age brackets (10-19 through 90-99)

Both have ~11 time snapshots (2018–2025), same municipality names as RPG, all CSV. They complement the existing data perfectly — RPG says "how many farms", size says "how big", age says "who runs them".

**Approach**: Fetch at runtime (same as RPG), integrate into existing screens (no new tabs), load in parallel but don't block navigation on secondary datasets.

---

## Data Layer

### Models

**`lib/data/models/farm_size_record.dart`** — one row per municipality (wide format):
- regionCode, regionName, municipalityCode, municipalityName
- countUpTo5, areaUpTo5 (≤5 ha)
- count5to20, area5to20
- count20to100, area20to100
- countOver100, areaOver100
- Computed: `totalFarms`, `totalArea`, `averageSize`

**`lib/data/models/farm_size_snapshot.dart`** — date + List\<FarmSizeRecord\>

**`lib/data/models/age_record.dart`** — one row per municipality × age bracket:
- regionCode, municipalityCode, municipalityName
- ageBracket (AgeBracket enum)
- farmCount

**`lib/data/models/age_snapshot.dart`** — date + List\<AgeRecord\>

**`lib/data/models/age_bracket.dart`** — enum with 9 values (age10to19 through age90to99):
- `fromCsvLabel()` handles the "okt.19" encoding bug (Serbian locale formats "10" as "okt" = October)
- `displayName` getter for UI labels

### Data Sources

**`lib/data/farm_size_source.dart`** — list of CsvSource entries (reuse existing CsvSource class):

| Date | URL |
|------|-----|
| 2018-02-26 | `https://data.gov.rs/s/resources/velichina-pg-poljoprivrednikh-gazdinstava-u-republitsi-srbiji/20180226-130942/Srbija_broj_gazinstava_po_opstinama_prema_velicini_gazdinstva.csv` |
| 2018-05-28 | `.../20180528-094517/Srbija_broj_gazinstava_po_opstinama_prema_velicini_gadinstva_05_28.csv` |
| 2019-07-17 | `.../20190717-093529/srbija-broj-gazinstava-po-opstinama-prema-velicini-gazdinstva-07-17-2019.csv` |
| 2020-06-15 | `.../20200615-125802/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-06-15-2020.csv` |
| 2021-06-10 | `.../20210610-095552/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-06-10-2021.csv` |
| 2021-12-01 | `.../20211201-134725/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-01-12-2021.csv` |
| ~~2022-09-28~~ | ~~DUPLICATE of 2021-12-01 (identical data) — skip~~ |
| 2024-10-25 | `.../20241025-091520/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-25-10-2024.csv` |
| 2024-12-31 | `.../20250109-092359/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-31-12-2024.csv` |
| 2025-07-07 | *XLSX — skip* |
| 2025-12-31 | `.../20260108-073041/srbija-broj-gazdinstava-po-opshtinama-prema-velichini-gazdinstava-31-12-2025.csv` |

**`lib/data/age_source.dart`** — list of CsvSource entries (11 snapshots, all CSV):

| Date | URL |
|------|-----|
| 2018-05-28 | `https://data.gov.rs/s/resources/rpg-broj-nosiotsa-aktivnikh-gazdinstava-prema-starosnoj-strukturi/20180528-151440/Srbija_broj_gazinstava_po_opstinama_prema_opsegu_godina_05_28.csv` |
| 2018-08-15 | `.../20180815-082823/Srbija_broj_gazinstava_po_opstinama_prema_opsegu_godina_08_15.csv` |
| 2019-07-17 | `.../20190717-093012/srbija-broj-gazinstava-po-opstinama-prema-opsegu-godina-07-17-2019.csv` |
| 2020-06-15 | `.../20200615-125557/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-06-15-2020.csv` |
| 2021-06-10 | `.../20210610-095103/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-06-10-2021.csv` |
| 2021-12-01 | `.../20211201-134534/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-01-12-2021.csv` |
| 2022-09-28 | `.../20220928-121547/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-28-09-2022.csv` |
| 2024-10-25 | `.../20241025-085950/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-25-10-2024.csv` |
| 2024-12-31 | `.../20250109-092421/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-31-12-2024.csv` |
| 2025-07-07 | `.../20250707-085436/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-07-07-2025.csv` |
| 2025-12-31 | `.../20260108-073012/srbija-broj-gazdinstava-po-opshtinama-prema-opsegu-godina-31-12-2025.csv` |

### Parsers

**URL verification confirmed all links work.** Key format quirks discovered across snapshots:

#### Farm Size CSV Quirks (parser must handle all)
- **Decimal formats vary**: `1963,0977` (comma only) vs `1.996,4809` (dot thousands + comma decimal)
- **Dash means zero**: Some snapshots use `-` instead of `0` for empty brackets
- **Spaces in headers**: Some snapshots have ` Broj PG <=5 ` with leading/trailing spaces (trim!)
- **Trailing semicolons**: Some files have extra empty columns at end of each row
- **Municipality code format**: Sometimes 3-digit (`010`), sometimes 2-digit (`10`)

**`lib/data/farm_size_parser.dart`** — follows CsvParser pattern:
- Header-based column mapping, Windows-1250 fallback, isolate-safe
- Column variants for: `NazivOpstineL`, `Broj PG <=5`, `Povrsina Ukupno <=5`, etc. (headers trimmed)
- Decimal parsing: strip dots (thousands sep), replace comma with period → `double.parse()`
- Dash `-` → 0 for both count and area fields
- Returns `List<FarmSizeRecord>`

#### Age CSV Quirks (parser must handle all)
- **Column name variants**: `BrojDomacinstva` (2018-2019) vs `BrojPG` (2024-2025) for the count column
- **Extra columns**: Some snapshots have `Reon`, `NazivRegije` columns; newer ones don't
- **Age label variants**: `10 - 19` (2019) vs `okt.19` (2025 — Serbian locale bug)
- **Trailing semicolons**: Extra empty columns in older files

**`lib/data/age_parser.dart`** — follows CsvParser pattern:
- Column variants: count column accepts both `BrojDomacinstva` and `BrojPG`
- AgeBracket.fromCsvLabel handles both `10 - 19` and `okt.19` formats
- Returns `List<AgeRecord>`

### Loaders + Providers

**`lib/data/farm_size_loader.dart`** and **`lib/data/age_loader.dart`** — follow DataLoader pattern (parallel fetch, per-source error handling, compute() isolate).

**`lib/providers/farm_size_provider.dart`** and **`lib/providers/age_provider.dart`** — keepAlive Riverpod providers, same pattern as `dataRepositoryProvider`.

### Loading Strategy

- RPG data remains the primary dataset — router redirect watches only `dataRepositoryProvider`
- Farm size and age providers start loading at app startup but don't block navigation
- Screens show secondary data sections with their own `asyncValue.when()` (inline loading/error states)
- If a secondary dataset fails, RPG screens work fully — secondary sections show inline error or hide

---

## Screen Integration

### PregledScreen — National Summary Additions

After existing rankings, add two new sections (each wrapped in own async watcher):

1. **Farm size distribution** (latest snapshot):
   - Headline stat: "Prosečna veličina: X ha"
   - Horizontal stacked bar showing national % breakdown by size bracket

2. **Age structure** (latest snapshot):
   - Headline stat: "Prosečna starost nosioca: X godina"
   - Horizontal bar chart with age bracket distribution

### OpstinaDetailScreen — Municipality Detail Additions

Below existing org form breakdown and trend chart, add:

1. **Farm size for this municipality**: Bar chart with 4 brackets (count). Small text showing total area.
2. **Age distribution for this municipality**: Bar chart with age brackets.

Both use NameResolver for municipality matching (same `canonicalKey` logic).

### TrendoviScreen — Dataset Selector

Add a **segmented button** (Material 3 `SegmentedButton`) above the municipality dropdown:
- "Gazdinstva" (existing RPG data, default)
- "Veličina"
- "Starost"

When dataset changes:
- Municipality dropdown stays (same resolver)
- Filter chips change to match the dataset:
  - Gazdinstva → OrgForm chips (existing)
  - Veličina → size bracket chips (≤5ha, 5-20ha, 20-100ha, >100ha)
  - Starost → age bracket chips (20-29, 30-39, etc.)
- Chart data/y-axis adjusts accordingly
- Line chart widget reused

### MapaScreen — Metric Selector

Add a **dropdown** or segmented button above the map:
- "Aktivna gazdinstva" (existing, default)
- "Prosečna veličina (ha)" — colour by average farm size
- "Prosečna starost" — colour by weighted average age of operators
- "% nosioca < 40 god." — colour by percentage of operators under 40

Choropleth recomputes colour gradient based on selected metric. Overlay info card shows relevant breakdown.

---

## Implementation Order (TDD)

### Phase 1: Farm Size Data Pipeline
1. FarmSizeRecord model + tests
2. FarmSizeSnapshot model
3. FarmSizeParser + tests (with real CSV sample as fixture)
4. FarmSizeSource (URL list)
5. FarmSizeLoader + tests
6. FarmSizeRepository provider + tests
7. Commit

### Phase 2: Age Data Pipeline
8. AgeBracket enum + tests (including "okt.19" handling)
9. AgeRecord model + tests
10. AgeSnapshot model
11. AgeParser + tests (with real CSV sample as fixture)
12. AgeSource (URL list)
13. AgeLoader + tests
14. AgeRepository provider + tests
15. Commit

### Phase 3: PregledScreen Integration
16. Add farm size summary section + tests
17. Add age summary section + tests
18. Commit

### Phase 4: OpstinaDetailScreen Integration
19. Add farm size detail section + tests
20. Add age detail section + tests
21. Commit

### Phase 5: TrendoviScreen Integration
22. Add dataset selector + conditional filter chips + tests
23. Wire farm size trend chart + tests
24. Wire age trend chart + tests
25. Commit

### Phase 6: MapaScreen Integration
26. Add metric selector + tests
27. Farm size choropleth + tests
28. Age choropleth (average age + % under 40) + tests
29. Commit

---

## Files

**New (data layer — ~14 files + generated + tests):**
- `lib/data/models/farm_size_record.dart`
- `lib/data/models/farm_size_snapshot.dart`
- `lib/data/models/age_record.dart`
- `lib/data/models/age_snapshot.dart`
- `lib/data/models/age_bracket.dart`
- `lib/data/farm_size_source.dart`
- `lib/data/age_source.dart`
- `lib/data/farm_size_parser.dart`
- `lib/data/age_parser.dart`
- `lib/data/farm_size_loader.dart`
- `lib/data/age_loader.dart`
- `lib/providers/farm_size_provider.dart` (+ .g.dart)
- `lib/providers/age_provider.dart` (+ .g.dart)

**Modified (screens — 4 files + tests):**
- `lib/screens/pregled/pregled_screen.dart`
- `lib/screens/opstine/opstina_detail_screen.dart`
- `lib/screens/trendovi/trendovi_screen.dart`
- `lib/screens/mapa/mapa_screen.dart`

**Key files to reuse/follow patterns from:**
- `lib/data/csv_parser.dart` — parser pattern
- `lib/data/data_loader.dart` — loader pattern
- `lib/data/data_source.dart` — CsvSource class + fetchBytes
- `lib/data/name_resolver.dart` — municipality matching (reused, not duplicated)
- `lib/providers/data_provider.dart` — provider pattern

---

## Verification

- `flutter analyze` — clean
- `flutter test` — all pass (existing + new)
- Manual: Confirm PregledScreen shows farm size + age summaries after data loads
- Manual: Confirm OpstinaDetail shows new sections for a municipality
- Manual: Confirm Trendovi dataset switcher works across all 3 datasets
- Manual: Confirm Mapa metric selector recolours the map correctly
- Manual: Kill network mid-load — confirm RPG screens work, secondary sections show error gracefully
