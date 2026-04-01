# LinkedIn Content Plan: Serbia Open Data Project

## Overview

A 14-post LinkedIn series (2/week, ~7 weeks) showcasing Milan's journey from senior Unity developer to Flutter + AI-assisted development, built around the Serbia Open Data project and related apps.

## Goals

- Reactivate a dormant LinkedIn presence with authentic, professional content
- Position Milan as a versatile senior developer exploring AI-assisted workflows
- Highlight giving back to the Serbian community through civic open source apps
- Attract attention from potential clients/employers who value adaptability and depth

## Content Pillars

Three recurring themes, with Journey as the backbone:

1. **Journey (~50%)** — Personal narrative. Why a 11yr Unity vet with 50M+ downloads is exploring Flutter and AI. The progression from curiosity to copy-paste learning to shipping real apps to full agentic development.

2. **Technical (~29%)** — War stories. Messy government data, encoding nightmares, TDD with an AI, visual redesign. Aimed at developers, shows depth without being tutorial-style.

3. **Community (~21%)** — Civic angle. Serbia's open data, what it reveals, why it matters, open sourcing the work. Aimed at the broader Serbian tech community and beyond.

## Post Sequence

| # | Pillar | Topic | Visual |
|---|--------|-------|--------|
| 1 | Journey | **Reintroduction** — 11 years in Unity, 50M+ downloads, and I finally gave Flutter a try. The love story that started with marketing and took years to act on. | App screenshot |
| 2 | Community | **Serbia's open data** — data.gov.rs exists and most people don't know about it. What's in there, why it matters. | Map screenshot |
| 3 | Journey | **The copy-paste phase** — First Flutter apps stitched together from chat AI suggestions. Honest about what that looks like and what you actually learn. | Phone with early app |
| 4 | Technical | **The encoding nightmare** — Government CSVs in Windows-1250, Serbian diacritics replaced with `?`. How we solved it. | Code snippet / before-after |
| 5 | Journey | **Saobracajke** — A LinkedIn post about car accident data inspired the first real app. CSV parsing, real users, live on Google Play. The jump from toy projects to shipping. | Play Store listing screenshot |
| 6 | Community | **The map** — Visualising Serbian municipality data as a choropleth. What the data reveals. | Coloured map |
| 7 | Journey | **Udahni** — From CSV to real APIs. Pollen data, closed testing, and the messy middle of mixing AI models and IDEs (VS Code, Cursor). | App screenshot or IDE screenshot |
| 8 | Technical | **Pairing with an AI** — What it's actually like coding with Claude. Honest take on strengths and limitations. | Workflow screenshot |
| 9 | Journey | **Going full agentic** — This project was built entirely with Claude Code. No chat copy-paste, no IDE switching. What changed and why. | Terminal/Claude Code screenshot |
| 10 | Technical | **TDD with an AI partner** — Does an LLM actually follow red-green-refactor? | Test output |
| 11 | Community | **Open sourcing it** — Why this is public, what the Serbian dev community could build next. GitHub repo: https://github.com/rus89/rpg-claude | GitHub repo screenshot |
| 12 | Technical | **The visual redesign** — From functional to polished. Design tokens, theming, before/after. | Before/after UI |
| 13 | Journey | **What 50M downloads taught me vs. what a civic app taught me** — Different games, same craft. | Side by side visual |
| 14 | Journey | **What's next** — Where this experiment is taking me. | TBD |

## Backstory Arc (Journey Pillar)

The journey posts follow a clear progression:

1. **Post 1**: Always loved Flutter since its release (marketing hooked him), but never had time alongside Unity contract work. Contract ended, found spare time, AI expansion created the catalyst.
2. **Post 3**: Early Flutter experiments were copy-paste from chat AI. Learned basic Flutter dev elements — project setup, architecture, production workflow. The hardest part was explaining project context to the AI, not the code itself. Didn't learn to think in Flutter — just learned to assemble it.
3. **Post 5**: Wanted real-world data. Inspired by a LinkedIn post about a web app visualising Serbian car accidents from open data. Built Saobracajke (Android, live on Google Play: https://play.google.com/store/apps/details?id=com.serbiaOpenData.saobracajke). Still mostly chat-AI-assisted.
4. **Post 7**: Next app — Udahni (pollen API data). Mixed agentic mode with chat AI. Switched between AI models and IDEs (VS Code, Cursor). Currently in closed testing — first production submission rejected by Google Play (they claimed testers didn't genuinely test the app; in reality, testers were friends and family, and the app is a free civic tool with no monetisation). Include this Google Play friction as part of the story.
5. **Post 9**: This project (RPG data) — built entirely with Claude Code. Full agentic workflow, no chat copy-paste, no IDE switching. The culmination of the progression.

Note: Posts 10-12 are Technical/Community posts that interrupt the journey arc intentionally — they provide variety and let the technical and civic stories breathe between the more personal posts.

## Raw Material for Key Posts

### Post 2: Serbia's Open Data

**data.gov.rs** is Serbia's open data portal. Most people don't know it exists. It has datasets covering agriculture, budgets, traffic, and a lot of other data useful for public services.

**The RPG dataset specifically:**
- RPG = Farm Registry (Registar Poljoprivrednih Gazdinstava)
- Tracks active and registered agricultural farms across 170+ Serbian municipalities
- Broken down by organizational form (sole proprietor, cooperative, LLC, etc. — 12 types)
- Complemented by auxiliary datasets: farm size distribution and age structure of farm operators
- 12 snapshots spanning 2018-2025 from the Administration for Agrarian Payments
- Source: semicolon-delimited CSVs, fetched from data.gov.rs at runtime

**Angle for the post:** This data is public, free, and nobody is using it. Serbia has an open data portal with real, useful information — and you can build apps on top of it.

### Post 4: The Encoding Nightmare

The government CSV files from data.gov.rs are encoded in Windows-1250, not UTF-8. The initial assumption was Latin-1, which silently corrupted Serbian diacritics (bytes 0x80-0x9F map differently). On top of that, the source data has Serbian letter đ (and sometimes č, š, ž, ć) replaced with literal `?` characters — baked into the CSV itself, not an encoding issue.

**The false start:** Used `latin1.decode` as a fallback, which produced invisible C1 control characters instead of Serbian letters. Hard to spot visually because the corruption was invisible in text rendering.

**The solution:** Built a custom Windows-1250 codec (256-entry byte-to-Unicode lookup table, no external dependency). Changed the normaliser to strip both diacritics AND `?` characters so that GeoJSON names (with proper đ) and CSV names (with `?`) produce matching keys. Example: "Čačak" and "?a?ak" both normalise to "aak".

**The lesson:** Always check raw byte values when debugging encoding. Don't assume UTF-8 or Latin-1 for government data.

### Post 6: The Map — Data Quality Observations

The municipality data across different yearly datasets (2023, 2024, 2025) is inconsistent: column headers change names between files, the number of columns varies between datasets, and Serbian diacritics are corrupted with `?`. The CSV parser had to use header-based column mapping with variant spellings (case-insensitive) instead of hardcoded column indices, because no two years format the data the same way.

### Post 10: TDD with an AI Partner

The CLAUDE.md enforces strict TDD: write a failing test first, run it to confirm failure, write only enough code to pass, run again, then refactor. In practice:
- Claude generally follows the red-green-refactor cycle when explicitly instructed
- It sometimes wants to write the implementation first and tests second — needs the rule to keep it honest
- The AI is good at writing comprehensive test cases, often catching edge cases the developer wouldn't think of
- Test output must be read carefully — the AI sometimes claims tests pass without verifying, or misreads failures
- Having 111 tests pass with clean analyzer output is a real confidence booster when an AI wrote most of the code

### Post 12: The Visual Redesign

Went from functional Flutter defaults to a cohesive visual identity:
- **Centralised theme** in a single `theme.dart`: olive green primary (#5C7A45), warm cream background (#F5F2EC)
- **Custom card styling** with `cardDecoration` helper — `BoxDecoration` with specific shadow (black @ 6%, blur 8, offset 0,2) because Flutter's `CardTheme` doesn't support custom box shadows
- **All screens updated**: themed typography, `ListView.separated` for cleaner lists, styled chips, icon cards, bottom sheet overlay on the map
- **Before/after** is dramatic — went from generic Material defaults to something that looks intentionally designed

### Post 8: Pairing with an AI — Strengths & Limitations

**Strengths:**
- Excellent at brainstorming and exploring approaches
- Makes accurate, detailed implementation plans
- Strong at analyzing code and debugging issues
- Good at writing code itself

**Limitations:**
- Can hallucinate and make mistakes — you can't blindly trust output
- Not always consistent about where to put things (e.g., plan file locations)
- Sometimes ignores CLAUDE.md rules when writing code, even when they're explicit

### Post 13: What 50M Downloads Taught Me vs. What a Civic App Taught Me

**Unity/B2B lessons:**
- Learned deep Unity concepts over many years
- Self-organization and independence — being responsible for HOW, not just WHAT
- Delivering tasks on time matters above all in contract work

**Civic app / AI-assisted lessons:**
- How to experiment with AI and utilise its power effectively
- Open data is mostly poorly formatted and organized — it takes real work to make it usable
- There's a lot of useful open data that nobody really knows about
- The feeling of making and learning new things that can be useful to someone else

### Post 14: What's Next

The game industry is in a strange spot right now. Milan likes making games but doesn't play them anymore. Predictions suggest the app industry will surpass gaming by the 2030s. Current direction:
- Would like to find a Unity gig in the near term
- Exploring Unity + AI integration
- Continuing to explore AI-assisted mobile app development
- Honest uncertainty — not a neat bow, just where things stand

## Style Guide

### Tone
- Professional but human — not corporate, not casual
- First person, honest, slightly reflective
- No humblebrags — state facts plainly
- No AI hype or doom — practical, grounded perspective
- Posts in English (international network)

### Structure
- Strong opening line (hook — never "I'm excited to announce...")
- 3-5 short paragraphs, ~150-250 words total
- End with a question or reflection, not a call to action
- 1-2 relevant hashtags max
- One visual per post

### Avoid
- "Thrilled to share..." / "Excited to announce..." openers
- Motivational platitudes
- Selling or pitching anything
- Mentioning passive income or B2C product ambitions
- Tagging Claude/Anthropic for engagement bait
- Posting on behalf of WarmApp Games — this is personal

## Cadence & Logistics

- **Schedule**: Monday and Thursday mornings (European time)
- **Process**: AI drafts posts, Milan reviews and adjusts voice/details before publishing
- **Batching**: Can draft a few at a time or go week by week
- **Visuals**: Milan prepares screenshots per post — specific capture instructions provided with each draft
- **Flexibility**: If a post gets good engagement, follow-up or reply thread possible. Posts can be swapped or skipped. Series ends naturally when project stories run out.
