# Android Google Play Store — release checklist

Use this when preparing an app update for the Play Store.

## Version

- Version is defined in `pubspec.yaml`: `version: 1.0.0+1` (versionName `1.0.0`, versionCode `1`). Bump before each store update (e.g. `1.0.1+2`).
- Android reads versionCode and versionName from Flutter; no separate edit in `build.gradle.kts` is needed.

## Signing

- `android/key.properties` contains `keyAlias` and `storeFile` (no passwords). File is gitignored.
- Upload-keystore password lives in macOS Keychain under service `rpg-claude-upload-keystore`, account `$USER`. Store it once with:
  ```bash
  security add-generic-password -a "$USER" -s "rpg-claude-upload-keystore" -w <password> -U
  ```
- `build.gradle.kts` reads `RELEASE_STORE_PASSWORD` and `RELEASE_KEY_PASSWORD` from the environment first, falling back to `key.properties` values if set. `scripts/build-release.sh` is the supported entry point — it pulls the password from Keychain and exports those env vars.
- Create an upload keystore if needed: [Flutter signing docs](https://docs.flutter.dev/deployment/android#signing-the-app).
- App is enrolled in Google Play App Signing — if the upload key is ever compromised, request a reset via Play Console.

## Build

From project root:

```bash
./scripts/build-release.sh
```

This runs `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/`. Output: `build/app/outputs/bundle/release/app-release.aab`. Upload this in Play Console. Keep `build/debug-info/` locally for crash symbolication (gitignored under `/build/`).

## Release config (already set)

- `compileSdk` is 36 (required by some plugins; backward compatible).
- `targetSdk` is 35 to meet [Google Play target API requirements](https://developer.android.com/google/play/requirements/target-sdk).
- `minSdk` follows Flutter default (21).

## Store listing (Play Console)

Done in Google Play Console, not in the repo:

- Short and full description, screenshots, feature graphic, app icon (icon is in the app as `@mipmap/launcher_icon`).
- Content rating, privacy policy URL if required, target audience.

## Before uploading

- Run `flutter analyze` and `flutter test`.
- Install and test a release build locally: `flutter run --release` or install the AAB on a device via internal testing.
