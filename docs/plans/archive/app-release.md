# Plan: Release Preparation (Android + Web)

## Context

Preparing the app for public release on Google Play Store and as a web app. The codebase is clean (no debug artifacts, 111 tests passing), but all config files still have Flutter template defaults for names, descriptions, and signing.

App name: **Registrovana Poljoprivredna Gazdinstva Srbije**
Platforms: **Android + Web**
Icons: Milan will provide custom assets.

---

## Step 1: App Name & Description — Update All Config Files

Every place the app name or description appears needs the real values.

| File | Field | Current | New |
|------|-------|---------|-----|
| `pubspec.yaml:2` | `description` | "Registrovana poljoprivredna gazdinstva" | "Registrovana Poljoprivredna Gazdinstva Srbije" |
| `lib/app.dart:16` | `title` | "RPG Srbija" | "Registrovana Poljoprivredna Gazdinstva Srbije" |
| `android/app/src/main/AndroidManifest.xml:3` | `android:label` | "rpg_claude" | "RPG Srbija" |
| `web/index.html:21` | `meta description` | "A new Flutter project." | "Registrovana Poljoprivredna Gazdinstva Srbije" |
| `web/index.html:26` | `apple-mobile-web-app-title` | "rpg_claude" | "RPG Srbija" |
| `web/index.html:32` | `<title>` | "rpg_claude" | "RPG Srbija" |
| `web/manifest.json:2-3` | `name` / `short_name` | "rpg_claude" | "Registrovana Poljoprivredna Gazdinstva Srbije" / "RPG Srbija" |
| `web/manifest.json:8` | `description` | "A new Flutter project." | "Registrovana Poljoprivredna Gazdinstva Srbije" |

Short name confirmed: **RPG Srbija** (used for home screen labels, browser tabs, etc.).

## Step 2: Android Release Signing

File: `android/app/build.gradle.kts`

1. Milan creates a release keystore:
   ```
   keytool -genkey -v -keystore ~/rpg-srbije-release.keystore \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias rpg-srbije
   ```
2. Create `android/key.properties` (already gitignored):
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=rpg-srbije
   storeFile=<path-to-keystore>
   ```
3. Update `build.gradle.kts` to load `key.properties` and use it for release signing config instead of debug.

## Step 3: App Icons (via flutter_launcher_icons)

1. Add `flutter_launcher_icons` to `dev_dependencies` in `pubspec.yaml`
2. Add config section in `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: false
     web:
       generate: true
       image_path: "assets/icon/app_icon.png"
       background_color: "#0175C2"
       theme_color: "#0175C2"
     image_path: "assets/icon/app_icon.png"
     adaptive_icon_background: "#0175C2"
     adaptive_icon_foreground: "assets/icon/app_icon.png"
   ```
3. Milan places high-res icon (1024x1024 recommended) at `assets/icon/app_icon.png`
4. Run `dart run flutter_launcher_icons`
5. This auto-generates all Android mipmap sizes, web icons, and favicon

**Blocked on**: Milan providing the icon image file.

## Step 4: Web Cleanup

- Update `web/manifest.json` theme/background colors if Milan wants something other than `#0175C2`
- Favicon and web icons will be handled by flutter_launcher_icons in Step 3

## Step 5: Clean Up pubspec.yaml

- Remove excessive boilerplate comments (the file is ~60% comments)
- Keep only essential config

---

## Out of Scope (not needed for this release)

- iOS configuration (not targeting iOS)
- R8/ProGuard (Flutter handles tree-shaking; ProGuard is optional and can be added later)
- Build flavors (single environment is fine for this app)
- `local.properties` is a local build artifact, not committed to git (it's in android/.gitignore by default via Flutter)

## Verification

- `flutter analyze` — clean
- `flutter test` — all pass
- `flutter build apk --release` — builds successfully with release signing
- `flutter build web` — builds successfully
- Inspect APK/web output for correct app name and icons
