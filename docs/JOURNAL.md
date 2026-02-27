---
name: Journal for AI agents
description: They use it to remember the most important elements about the project, so they can recall it later.
---

# Agent Journal

- Each entry: `## YYYY-MM-DD — [Agent/session note]` followed by freeform notes.
- Read this at session start. Append entries; never delete existing ones.
- keep elements organized.

## 2026-02-27 — Code review follow-ups

Two issues deferred until implementation is complete (Milan's call — branch is still WIP):

1. `lib/main.dart` — still Flutter default boilerplate; missing `// ABOUTME:` header (required by CLAUDE.md). Needs replacement with the real app entry point before final review.
2. `test/widget_test.dart` — tests the counter demo, not the RPG app. Will break once `main.dart` is replaced. Needs updating alongside `main.dart`.

**Remind Milan to fix both before marking implementation done.**
