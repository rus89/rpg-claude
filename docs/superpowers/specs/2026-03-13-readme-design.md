# README Design Spec

## Context

The current README is a Flutter boilerplate placeholder. This spec describes a professional, feature-forward README targeting GitHub visitors (developers, open data enthusiasts, recruiters) for the RPG Serbia agricultural data visualization app.

## Decisions

- **Audience**: GitHub visitors
- **Language**: English (Serbian UI terms explained in parentheses)
- **Structure**: Feature-Forward Showcase (Option A)
- **License**: MIT
- **Screenshots**: User-provided, at `docs/screenshots/*.jpg`

---

## Sections

### 1. Hero

- Title: `RPG Serbia — Agricultural Farm Data Explorer`
- One-liner: Interactive Flutter app visualizing registered agricultural farm data across Serbian municipalities, powered by open government data from data.gov.rs
- Badges: Flutter, Dart, License: MIT, Tests: 205 passing

### 2. Screenshots

- 2x2 grid using images from `docs/screenshots/`
- Files: `pregled.jpg`, `opstine.jpg`, `trendovi.jpg`, `mapa.jpg`
- Captions: Pregled (Overview), Opštine (Municipalities), Trendovi (Trends), Mapa (Map)
- Intro line above grid summarizing the app visually

### 3. Features

**Three Datasets:**
- Farm Registry (RPG) — active/registered farms by municipality and organizational form (12 snapshots, 2018–2025)
- Farm Size Distribution — farms categorized by land area with counts and total hectares (9 snapshots)
- Age Structure — farm operator counts by 10-year age brackets (11 snapshots)

**Five Screens:**
- Pregled — National dashboard: summary cards, org form bar chart, top/bottom municipality rankings, farm size and age summaries
- Opštine — Searchable municipality list with detail view: trend lines, org form breakdown, size and age distributions
- Trendovi — Multi-dataset trend explorer with dataset selector, municipality filter, and category chips
- Mapa — Choropleth map with 4 selectable metrics (farm count, average size, average age, % young operators), zoom controls, tap-to-inspect overlay
- O aplikaciji — Data source attribution and screen-by-screen guide

**Technical Highlights:**
- Resilient parallel CSV loading — individual source failures don't break the app
- Header-based CSV parsing handles government data quirks (encoding, diacritics, format inconsistencies)
- Responsive layout adapting to mobile and tablet
- 205 widget and unit tests

### 4. Tech Stack

Table format:

| Category | Technology |
|---|---|
| Framework | Flutter 3.11+ / Dart 3.11+ |
| State Management | Riverpod (code-generated) |
| Navigation | GoRouter |
| Charts | fl_chart |
| Maps | flutter_map + OpenStreetMap tiles |
| Data | CSV from data.gov.rs, GeoJSON (GADM L2) |
| Design | Material Design 3 |

### 5. Data Sources

- Source: Uprava za agrarna plaćanja (Administration for Agrarian Payments), Republic of Serbia
- Three datasets listed with name, contents, snapshot count
- Note: all data fetched at runtime from data.gov.rs — app bundles no CSV data, only GeoJSON boundaries
- Disclaimer: independent project, not affiliated with or endorsed by any Serbian government body

### 6. Getting Started

Prerequisites:
- Flutter 3.11+ (Dart 3.11+)
- Android SDK (API 21+) or iOS/Xcode 14+

Commands:
```
git clone https://github.com/rus89/rpg-claude.git
cd rpg-claude
flutter pub get
dart run build_runner build
flutter run
```

Testing:
```
flutter test       # 205 tests
flutter analyze    # 0 issues
```

No environment variables, API keys, or .env files needed.

### 7. Architecture Overview

Brief paragraph: reactive data flow (app start → loading screen → parallel CSV fetch → Riverpod caches → GoRouter redirects to dashboard). Municipality name normalization via NameResolver.

Abbreviated directory tree:
```
lib/
├── data/           # CSV parsers, loaders, sources, name resolution
│   └── models/     # Domain models (records, snapshots, enums)
├── providers/      # Riverpod async providers (generated)
├── screens/        # 5 screens, each in own directory
├── navigation/     # GoRouter config + bottom nav shell
├── layout/         # Responsive breakpoints + scaffold
└── theme.dart      # Material 3 design tokens
```

### 8. Testing

One line: 205 unit and widget tests covering CSV parsing, data loading, name resolution, providers, and all screens.

### 9. License + Footer

- MIT License — link to LICENSE file
- Footer: "Built with Flutter and open data from data.gov.rs"

---

## Files to Create/Modify

- `README.md` — full rewrite
- `LICENSE` — MIT license file (new)
