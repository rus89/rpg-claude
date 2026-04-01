# LinkedIn Content Series Implementation Plan

> **For agentic workers:** This plan contains 14 LinkedIn post drafts grouped into 7 weekly batches. Each task = one week (2 posts). Milan reviews and approves each batch before the next is drafted. Use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Draft all 14 LinkedIn posts for Milan's series showcasing his journey from Unity to Flutter + AI-assisted development.

**Architecture:** Posts are grouped into weekly batches (Mon + Thu). Each post includes the full draft text, visual instructions, and hashtags. Milan reviews each batch, adjusts voice/details, then publishes.

**Tech Stack:** LinkedIn, screenshots from the app/terminal/Play Store.

---

## Week 1

### Task 1: Post 1 — Reintroduction (Monday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
I've spent 11 years building games in Unity. Over 50 million downloads across titles I've worked on as a solo B2B contractor.

A few months ago, a contract ended. For the first time in years, I had spare time. And there was this framework I'd been watching since its launch — Flutter. I fell for it the moment I saw the first demo. The hot reload, the single codebase, the widget composition model. But I never had a reason to step away from Unity long enough to actually try it.

Then AI-assisted coding started getting genuinely useful, and the timing clicked. I decided to use the gap between contracts to learn Flutter — not from tutorials, but by building real apps with an AI as my coding partner.

This is the first post in a series about that experiment. What I built, what I learned, what surprised me. No hype, no "AI will replace developers" takes. Just an honest account of what happens when a senior game developer picks up a new framework with a very unusual collaborator.

Starting with the basics: what do you actually learn when an AI writes most of the code?

#Flutter #GameDev
```

- [ ] **Step 2: Visual instructions**

Screenshot of the RPG app in its current polished state — the Pregled (overview) screen showing summary cards and charts. Should look professional and finished, since this is the "here's what I ended up building" hook.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 2: Post 2 — Serbia's Open Data (Thursday)

**Pillar:** Community

- [ ] **Step 1: Draft post**

```
Serbia has an open data portal. Most people I've talked to — including Serbian developers — don't know it exists.

data.gov.rs publishes datasets covering agriculture, budgets, traffic, and dozens of other categories useful for public services. All free, all downloadable, and almost nobody is building anything with it.

I started digging into the agricultural data. The RPG — Registar Poljoprivrednih Gazdinstava (Farm Registry) — tracks every registered agricultural entity across 170+ Serbian municipalities. How many farms, what type of organization, who owns them, how old the operators are. Twelve snapshots spanning 2018 to 2025, published by the Administration for Agrarian Payments.

The data comes as semicolon-delimited CSVs. It's not pretty — more on that in a future post — but it's real, and it tells a story about Serbian agriculture that no one is reading yet.

I built a mobile app to make that story visible. A choropleth map, trend charts, municipality breakdowns — all from open government data that was just sitting there.

What public datasets in your country are going unused?

#OpenData #Serbia
```

- [ ] **Step 2: Visual instructions**

Screenshot of the Mapa screen showing the choropleth map of Serbian municipalities with coloured polygons. Should show the full map view with visible colour variation between municipalities.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Week 2

### Task 3: Post 3 — The Copy-Paste Phase (Monday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
My first Flutter apps were, honestly, assembled from copy-paste.

I'd describe what I wanted to a chat AI, get a block of code back, paste it in, run it, see what happened. If it broke, I'd paste the error back and ask for a fix. Repeat until it worked.

I learned things from this. Project setup, folder structure, how to configure builds for production, the basics of widget composition. Real skills, just absorbed in an unusual way.

But the hardest part wasn't the code — it was explaining what I actually wanted. A chat AI has no memory of your project between messages. Every session, you're re-explaining your architecture, your constraints, your file structure. The code it generates is technically correct but context-free.

I came out of that phase knowing how to assemble a Flutter app. I did not come out of it knowing how to think in Flutter. There's a difference between being able to build something and understanding why it works.

That gap is what pushed me toward building something real — with real data, real users, and a problem worth solving.

What was your "copy-paste phase" with a new technology?

#Flutter #AI
```

- [ ] **Step 2: Visual instructions**

Screenshot of an early/simple Flutter app on a phone — ideally one of the practice apps Milan built during this phase. If none are available, a screenshot of a chat AI conversation showing a Flutter code block being generated could work.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 4: Post 4 — The Encoding Nightmare (Thursday)

**Pillar:** Technical

- [ ] **Step 1: Draft post**

```
The Serbian government publishes CSV data in Windows-1250 encoding. I assumed it was UTF-8. Then Latin-1. Both were wrong, and both corrupted the data silently.

Latin-1 decoding maps bytes 0x80-0x9F to invisible C1 control characters instead of Serbian letters. The text looks fine at a glance — the corruption is invisible in most renderers. Municipality names appeared in the app with no visible errors, but none of them matched our GeoJSON map data. The map showed 170 grey polygons.

It got worse. The source CSVs replace the Serbian letter đ — and sometimes č, š, ž, ć — with a literal question mark. Not a Unicode issue. It's baked into the data itself. The city of Čačak appears as ?a?ak in the government files.

The fix: a custom Windows-1250 codec (256-entry lookup table, no external dependency) and a normaliser that strips both proper diacritics and question marks. "Čačak" and "?a?ak" both normalise to "aak" — ugly, but it works.

Lesson: never assume encoding. Check the raw bytes. Government data from the Balkans has its own character.

#DataEngineering #OpenData
```

- [ ] **Step 2: Visual instructions**

A side-by-side or before/after image. Option A: code snippet showing the Windows-1250 lookup table or the normaliser function. Option B: a terminal/log showing corrupted vs. correct municipality names. The "?a?ak" example is visually striking — consider highlighting it.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Week 3

### Task 5: Post 5 — Saobracajke (Monday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
A LinkedIn post changed my direction.

Someone shared a web app that visualised car accident data in Serbia — built entirely from open government data. I thought: this could be a mobile app. Android, specifically, because it's the easiest platform to publish on.

That's how Saobracajke was born. An Android app that parses Serbian traffic accident data and makes it browsable and visual. Real data, real users, live on Google Play.

It was still mostly chat-AI-assisted development. But something shifted. The problems were real — CSV parsing edge cases, data inconsistencies across years, building something strangers would actually use. Copy-paste wasn't enough anymore. I had to understand what the code was doing, because the data didn't behave the way the AI expected.

This was the jump from toy projects to shipping. The moment I stopped learning Flutter as an exercise and started using it to build something people could download.

The app is small and simple. But it's live, it works, and it taught me more than any tutorial.

What project turned a technology from "something you're learning" into "something you're using"?

https://play.google.com/store/apps/details?id=com.serbiaOpenData.saobracajke

#Flutter #OpenData
```

- [ ] **Step 2: Visual instructions**

Screenshot of the Saobracajke Play Store listing, or the app itself running on a phone. The Play Store listing is more compelling here — it shows "this is real, it's published, people can download it."

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 6: Post 6 — The Map (Thursday)

**Pillar:** Community

- [ ] **Step 1: Draft post**

```
170+ municipalities. Twelve years of agricultural data. One map.

Building a choropleth map of Serbian municipalities sounds straightforward until you actually try it with government data. The column headers change names between yearly datasets. The number of columns varies from year to year. And Serbian diacritics — č, ć, ž, š, đ — are randomly replaced with question marks.

No two years format the data the same way.

The CSV parser couldn't use hardcoded column indices. It had to map headers by name, with variant spellings, case-insensitive. A municipality called "Čačak" in one file appears as "?a?ak" in another. The parser handles both.

The result is a map where every municipality is coloured by how many active agricultural holdings it has. You can tap any municipality and see the breakdown — what types of farms, how many are active vs. registered.

It's not a polished government dashboard. It's a mobile app, built from freely available data, by one developer and an AI. And it shows something real about how agriculture is distributed across Serbia.

Sometimes the most interesting thing about public data is that nobody looked at it.

#OpenData #Serbia
```

- [ ] **Step 2: Visual instructions**

Screenshot of the Mapa screen with the coloured choropleth and a municipality overlay open, showing the breakdown popup. The overlay showing farm data for a specific municipality is the most compelling visual here.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Week 4

### Task 7: Post 7 — Udahni (Monday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
After Saobracajke, I wanted a harder problem. CSV files are static — download, parse, display. I wanted to work with a live API.

Serbia has a pollen monitoring network. Real-time data on allergen concentrations, published through an API. I built Udahni — an app that shows current pollen levels for Serbian cities.

This was the messy middle of my AI experiment. I was switching between AI models, jumping between VS Code and Cursor, mixing chat-based assistance with agentic coding modes. Some days I'd get beautiful, working code in minutes. Other days I'd spend hours debugging something the AI introduced three context switches ago.

The app works. It's currently in closed testing on Google Play. My first production submission was rejected — Google claimed my testers hadn't genuinely tested the app. Every tester was a friend or family member. The app is free, has no monetisation, and exists purely to show people pollen levels. But Google's review process doesn't distinguish between a startup's MVP and a solo developer's civic side project.

Still working through that. The app works, the data flows, and eventually it'll be live. Some lessons aren't technical.

Have you ever had a project held up by something completely unrelated to the code?

#Flutter #IndieApp
```

- [ ] **Step 2: Visual instructions**

Screenshot of the Udahni app showing pollen data, or a screenshot of the IDE workspace (VS Code or Cursor) with Flutter code open. If the app screenshot is more polished, go with that.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 8: Post 8 — Pairing with an AI (Thursday)

**Pillar:** Technical

- [ ] **Step 1: Draft post**

```
I've now built three apps with AI assistance. Here's what I've actually observed — no hype, no doom.

What it's good at: brainstorming. Genuinely good. You describe a vague idea and it helps you explore approaches you wouldn't have considered. It makes detailed implementation plans that are usually accurate. When something breaks, it's strong at analyzing code and tracking down the bug. And it writes solid code — not perfect, but solid.

What it's not good at: consistency. It can hallucinate — confidently generate code that references APIs or methods that don't exist. It sometimes ignores explicit rules you've set up, even when they're written in a configuration file it's supposed to read every session. It's not always consistent about where files should go or how things should be organized.

The biggest adjustment wasn't technical. It was learning that AI assistance is a collaboration, not a service. You can't hand it a task and walk away. You have to review its output, catch its mistakes, push back when it's wrong. The developers who will get the most out of these tools are the ones who already know how to code — because you need to know when the AI is subtly wrong.

It's a multiplier, not a replacement. And the multiplier depends entirely on you.

#AI #SoftwareDevelopment
```

- [ ] **Step 2: Visual instructions**

Screenshot of a Claude Code terminal session or a conversation showing a back-and-forth debugging exchange. Something that shows the collaborative nature — not just generated code, but the dialogue.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Week 5

### Task 9: Post 9 — Going Full Agentic (Monday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
My first Flutter apps: copy-paste from chat AI. My second: mixing chat with agentic mode across multiple IDEs. My third: built entirely in Claude Code. No IDE. No copy-paste. Just a terminal and conversation.

The shift was gradual but the difference is real. In chat mode, you're the architect and the AI is a code generator. In agentic mode, the AI reads your files, understands your project structure, runs tests, fixes its own mistakes. You're still steering, but the collaboration is deeper.

For this project — a Flutter app visualising Serbian agricultural data — I set up a CLAUDE.md file with strict rules. Test-driven development. Small commits. No shortcuts. The AI reads this file at the start of every session and follows it. Mostly.

The result: 111 tests, clean static analysis, five screens including a choropleth map, all built through conversation. I write the requirements, review the output, push back when something's wrong. The AI writes the code, runs the tests, debugs the failures.

It's not "AI built my app." It's closer to pair programming where your partner never gets tired but occasionally forgets what you told them yesterday.

The code is open source if you want to see what AI-agentic Flutter development actually produces.

#AI #Flutter
```

- [ ] **Step 2: Visual instructions**

Screenshot of Claude Code terminal showing a work session — ideally showing test output or a commit being made. The terminal aesthetic reinforces the "no IDE, just conversation" message.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 10: Post 10 — TDD with an AI Partner (Thursday)

**Pillar:** Technical

- [ ] **Step 1: Draft post**

```
Can an AI actually follow test-driven development?

I enforce strict TDD in my CLAUDE.md rules: write a failing test, run it, confirm it fails, write minimal code to pass, run again, refactor. Red-green-refactor. The AI reads these rules at the start of every session.

What actually happens: it mostly follows the cycle. When explicitly instructed, it writes the test first, runs it, sees it fail, then implements. But left to its own instincts, it wants to write the implementation first. The TDD discipline has to be imposed — the AI doesn't naturally gravitate toward it.

Where it surprised me: test coverage. The AI catches edge cases I wouldn't have thought of. Boundary conditions, null handling, format variations in input data. 111 tests across the project, and most of the interesting ones came from the AI noticing a scenario I missed.

Where it needs watching: it sometimes claims tests pass without actually checking the output. Or it misreads a failure and says everything's green when it isn't. You have to verify. Trust but verify, except with more emphasis on the verify.

The result — 111 passing tests with clean analyzer output on a project where an AI wrote most of the code — is honestly more reassuring than I expected.

#TDD #AI
```

- [ ] **Step 2: Visual instructions**

Screenshot of terminal showing `flutter test` output with all tests passing — the "111 tests, 0 failures" output. Clean, simple, speaks for itself.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Week 6

### Task 11: Post 11 — Open Sourcing It (Monday)

**Pillar:** Community

- [ ] **Step 1: Draft post**

```
I'm open sourcing this project.

The Flutter app that visualises Serbian agricultural data — the one I've been writing about in this series — is on GitHub. The code, the tests, the CLAUDE.md configuration, the commit history showing how it was built with an AI partner. All of it.

https://github.com/rus89/rpg-claude

Why open source a side project? A few reasons.

Serbia's open data portal has real, useful datasets that nobody is building with. If seeing a working example lowers the barrier for another developer to try, that's worth it. The more apps that exist on top of data.gov.rs, the more pressure there is to keep improving the data quality.

I also think there's value in showing what AI-assisted development actually looks like in practice — not a demo, not a tutorial, but a real project with messy data, edge cases, and 111 tests. The commit history is the real story.

If you're a Serbian developer curious about open data, or any developer curious about what AI-agentic coding produces, take a look. PRs welcome, feedback even more so.

What open data in Serbia would you want to see turned into an app?

#OpenSource #Serbia
```

- [ ] **Step 2: Visual instructions**

Screenshot of the GitHub repository page — showing the README, the file structure, and the commit count. Ideally shows that it's a real, active project, not a skeleton repo.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 12: Post 12 — The Visual Redesign (Thursday)

**Pillar:** Technical

- [ ] **Step 1: Draft post**

```
The app worked. It looked like a default Flutter app. Time to fix that.

The visual redesign was one of the more interesting parts of this project. Not because it's groundbreaking design — it's a data app, not a consumer product — but because it tested whether an AI partner can make intentional aesthetic choices.

The approach: centralise everything in a single theme.dart file. Olive green primary (#5C7A45), warm cream background (#F5F2EC). All typography, card styles, chip themes, input decorations defined once and referenced everywhere.

One specific challenge: Flutter's CardTheme doesn't support custom box shadows. The default Material elevation shadow looks flat and generic. So we built a cardDecoration helper — a BoxDecoration with a precise shadow (black at 6% opacity, blur 8, offset 0,2). Small detail, big difference.

Every screen got updated. Themed typography instead of hardcoded styles. ListView.separated for cleaner lists. Styled chips on the trend filters. Icon cards on the about screen. A proper bottom sheet overlay on the map.

The before/after is dramatic. Same data, same layout structure, completely different feel. Going from "this is a prototype" to "this was designed" took one focused redesign pass.

How much does visual polish matter for data apps?

#Flutter #Design
```

- [ ] **Step 2: Visual instructions**

Side-by-side before/after comparison. Left: the app with default Material styling. Right: the app after the redesign with olive green theme and cream background. If Milan doesn't have a "before" screenshot, the current polished state alone works — but the comparison is much more compelling.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Week 7

### Task 13: Post 13 — 50M Downloads vs. Civic App (Monday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
Eleven years of Unity. Games with 50 million downloads. Then a few months building civic apps with Flutter and an AI.

Different worlds. Here's what each one taught me.

Unity and B2B contract work taught me depth. Mastering a single engine over years. Self-organization — when you're a solo contractor, nobody tells you how to solve a problem. You own the HOW, not just the WHAT. And above all: deliver on time. That's the job.

Building civic apps with AI taught me breadth. How to experiment with new tools and get productive fast. How to use an AI partner effectively — not as a crutch, but as a collaborator with specific strengths and limitations.

It also taught me something unexpected about data. Open government data is mostly poorly formatted, inconsistently organized, and unknown to the public. Making it usable takes real engineering work. But there's a lot of it, and nobody's building with it.

The most surprising difference: the feeling. Contract work is satisfying when you ship on deadline. Building something that could be useful to people — even a small, free app about farm registries — feels different. It's not better or worse. Just different.

Both are craft. Same principles, different materials.

What's the most different project you've worked on from your "main" thing?

#GameDev #Flutter
```

- [ ] **Step 2: Visual instructions**

Side-by-side visual: a game screenshot (or Unity editor) on one side, the Serbia Open Data app on the other. If Milan doesn't want to show client work, a generic Unity editor screenshot alongside the RPG app works.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

### Task 14: Post 14 — What's Next (Thursday)

**Pillar:** Journey

- [ ] **Step 1: Draft post**

```
I started this series after a contract ended and spare time appeared. Fourteen posts later, here's where I am.

Honestly? I'm not sure what's next. And I think that's worth saying out loud.

The game industry is in a strange place right now. I've spent over a decade making games, and I still love the craft — but I haven't played a game in longer than I'd like to admit. Some predictions suggest the app industry will surpass gaming by the 2030s. I don't know if that's right, but I notice it.

What I do know: I want to find my next Unity gig. That's still my deepest skill and where I deliver the most value. But I'm also going to keep exploring Unity and AI integration — the tooling is moving fast and game development will look different in two years.

And I'll keep building mobile apps. Not because I'm pivoting away from games, but because the experiment worked. I learned a new framework, shipped real apps, and discovered that Serbian open data is a surprisingly rich and untapped space.

This project — from copy-paste to agentic development, from static CSVs to live APIs to choropleth maps — wasn't a career change. It was a reminder that the best way to stay sharp is to build things that feel unfamiliar.

Thanks for following along.

#GameDev #Flutter #AI
```

- [ ] **Step 2: Visual instructions**

This is the closing post. Options: (A) a collage of all three apps (Saobracajke, Udahni, RPG), (B) a photo of Milan himself (most personal, strongest for a closing post), (C) the RPG app's map screen as a callback to where the series started. Milan chooses.

- [ ] **Step 3: Milan reviews and adjusts voice**

---

## Publishing Checklist (applies to every post)

Before publishing each post:

- [ ] Milan has reviewed and adjusted the draft text
- [ ] Visual/screenshot is prepared and attached
- [ ] Post is scheduled for Monday or Thursday morning (European time)
- [ ] No mentions of passive income, B2C ambitions, or WarmApp Games
- [ ] No "thrilled/excited to share" openers
- [ ] Post ends with a question or reflection, not a CTA
- [ ] 1-2 hashtags max
- [ ] Word count is 150-250
