---
name: release
description: Steps to perform a release build for the Flutter app
---

## Release Build

1. Increment versionCode and versionName in pubspec.yaml
2. Verify signing config in android/app/build.gradle points to valid keystore
3. Run `flutter clean && flutter build appbundle --release`
4. Verify output: `jarsigner -verify build/app/outputs/bundle/release/app-release.aab`
5. Commit version bump and tag with `git tag v<version>`
