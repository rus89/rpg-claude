---
name: review
description: Steps to perform a code review validation for the Flutter app
---

## Code Review Validation

1. Read the review findings provided by the user
2. For each finding, locate the actual code in the codebase
3. Classify each as VALID or FALSE ALARM with evidence
4. For valid findings, suggest a fix
5. Run `flutter analyze` to confirm no regressions
