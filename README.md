# WPA Bible Engagement App

A Flutter app (iOS and Android) for the WPA community: Bible series with daily engagement content, prayer requests, testimonies and a discussion forum, backed by Firebase. The backend (Firestore rules, Cloud Functions, emulator setup) lives in a separate repo, [wpa-be-firebase](https://github.com/waterloo-pentecostal-assembly/wpa-be-firebase).

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): layers and dependency rules, DI, state, routing, deep links, testing, and how to add a feature.
- [`docs/ui/FEATURES.md`](docs/ui/FEATURES.md): features and business rules.
- [`docs/ui/SCREENS.md`](docs/ui/SCREENS.md): the UI contract, screen by screen.
- [`docs/ui/UI_REBUILD_GUIDE.md`](docs/ui/UI_REBUILD_GUIDE.md): what a UI redesign may and may not change.
- [`docs/firestore/`](docs/firestore/): Firestore schema notes (`bible_series`, `completions`).

## Prerequisites

- **Flutter stable 3.50.0**, the version CI pins in `.github/workflows/ci.yml`. The resolved dependencies in `pubspec.lock` need at least Flutter 3.47 / Dart 3.13. Install it from [flutter.dev](https://docs.flutter.dev/get-started/install), then run `flutter doctor` and fix any errors.
- **Android:** Android Studio / Android SDK and JDK 17 (the Gradle build targets Java 17).
- **iOS (macOS only):** Xcode and CocoaPods.

Then fetch dependencies:

```sh
flutter pub get
```

## Firebase config files (required, gitignored)

The app won't build without these files. They are not in the repo; get them from the Firebase console (*Project settings → General → Your apps*). Ask for access to the projects.

| File | Firebase project | App |
|---|---|---|
| `android/app/src/dev/google-services.json` | `wpa-be-app-dev` | Android `church.wpassembly.beapp.dev` |
| `android/app/src/prod/google-services.json` | `wpa-be-app` | Android `church.wpassembly.beapp` |
| `ios/config/dev/GoogleService-Info.plist` | `wpa-be-app-dev` | iOS `church.wpa.beapp.dev` |
| `ios/config/prod/GoogleService-Info.plist` | `wpa-be-app` | iOS `church.wpa.beapp` |

You don't need to add the iOS plists to the Xcode project. The **Firebase setup** build phase copies `ios/config/<flavor>/GoogleService-Info.plist` into the app bundle, choosing the flavor from the build configuration name (`Debug-Dev`, `Release-Prod`, …).

Optional: `android/key.properties` (also gitignored) holds the release keystore (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Without it, release builds are not signed with the upload key; debug builds work fine.

## Flavors

| Mode | Entry point (`-t`) | `--flavor` | iOS scheme | Backend |
|---|---|---|---|---|
| `dev` | `lib/app/flavors/main_dev.dart` | `dev` | `Dev` | Firebase project `wpa-be-app-dev` |
| `local_dev` | `lib/app/flavors/main_local_dev.dart` | `dev` | `Dev` | Firestore on a **local emulator** at `localhost:8081` (`10.0.2.2:8081` from the Android emulator). Auth, Storage and Messaging still use `wpa-be-app-dev`. |
| `prod` | `lib/app/flavors/main_prod.dart` | `prod` | `Prod` | Firebase project `wpa-be-app` |

`local_dev` has no native flavor of its own; it reuses `dev`. Start the Firestore emulator first (see [wpa-be-firebase](https://github.com/waterloo-pentecostal-assembly/wpa-be-firebase)).

App Check uses the debug providers in `dev` and `local_dev`, and Play Integrity / App Attest (with DeviceCheck fallback) in `prod`. If App Check is enforced on the dev project, register the debug token that the app prints in the device logs on first run (Firebase console → App Check → Manage debug tokens).

## Running

```sh
# dev (remote dev Firebase)
flutter run -t lib/app/flavors/main_dev.dart --flavor dev

# local_dev (Firestore emulator must be running)
flutter run -t lib/app/flavors/main_local_dev.dart --flavor dev

# prod
flutter run -t lib/app/flavors/main_prod.dart --flavor prod
```

### iOS notes

- `flutter run` / `flutter build ios` run `pod install` for you. If Xcode reports that the Pods sandbox is out of sync, run `cd ios && pod install`.
- To change signing or run from Xcode, open `ios/Runner.xcworkspace` (not the `.xcodeproj`) and pick the `Dev` or `Prod` scheme.
- iPhone is portrait-only; iPad and Android support all orientations.

### Background audio

Audio keeps playing in the background and when the app is closed, with lock screen / notification controls (`audio_service`). This needs the platform setup already in the repo: the iOS `audio` background mode in `Info.plist`, and on Android `MainActivity` extending `AudioServiceActivity` plus the `AudioService` / `MediaButtonReceiver` entries and foreground-service permissions in `AndroidManifest.xml`. Verify background and lock screen behaviour on physical devices. See `docs/ARCHITECTURE.md` §9b.

### VS Code

`.vscode/` is gitignored. To run and debug from VS Code, create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "wpa-be-app-dev",
      "request": "launch",
      "type": "dart",
      "program": "lib/app/flavors/main_dev.dart",
      "args": ["--flavor", "dev"]
    },
    {
      "name": "wpa-be-app-local-dev",
      "request": "launch",
      "type": "dart",
      "program": "lib/app/flavors/main_local_dev.dart",
      "args": ["--flavor", "dev"]
    },
    {
      "name": "wpa-be-app-prod",
      "request": "launch",
      "type": "dart",
      "program": "lib/app/flavors/main_prod.dart",
      "args": ["--flavor", "prod"]
    }
  ]
}
```

## App version (`APP_VERSION`)

The Profile screen shows `Version <x>`, taken from `AppInfo.version` in `lib/app/app_info.dart`:

```dart
String.fromEnvironment('APP_VERSION', defaultValue: '3.0.1');
```

- Pass `--dart-define=APP_VERSION=x.y.z` to `flutter run` or `flutter build` to override it.
- The default must match `version:` in `pubspec.yaml`. `test/app/routes_test.dart` fails if they differ, so update both when you bump the version.

## Checks (same as CI)

CI (`.github/workflows/ci.yml`) runs on pull requests to `dev` and `master`:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Tests need no Firebase project or config files. They use fakes, `mocktail` and `fake_cloud_firestore`. Layout:

- `test/domain`: rules
- `test/application`: cubits
- `test/infrastructure`: repositories
- `test/app`: router, redirects, deep links
- `test/presentation`: screen smoke tests at phone and tablet widths, plus layout primitives

## Building for release

Use the `prod` flavor and pass the version:

```sh
# Android
flutter build appbundle -t lib/app/flavors/main_prod.dart --flavor prod --dart-define=APP_VERSION=3.0.1
flutter build apk       -t lib/app/flavors/main_prod.dart --flavor prod --dart-define=APP_VERSION=3.0.1

# iOS
flutter build ipa -t lib/app/flavors/main_prod.dart --flavor prod --dart-define=APP_VERSION=3.0.1
```

Release binaries are published as GitHub Releases, not committed (`releases/` is gitignored).
