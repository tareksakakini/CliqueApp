# Clique Android

This module contains the first production-ready Android implementation of Clique's outing planner. The code mirrors the SwiftUI architecture: passwordless phone authentication, Firebase-backed events/friends, OneSignal routing, and a Compose-driven UI that uses the same models/formatters as the iOS version.

## Project structure

```
CliqueAndroid/
├── app/src/main/java/com/clique/app
│   ├── core/            # Dependency container, auth helpers, notifications, networking
│   ├── data/            # Shared models + Firebase repository
│   ├── ui/              # Compose navigation, screens, and theme
│   └── MainActivity.kt  # Entry point
├── app/src/main/res     # Android resources (themes, strings, icons, etc.)
├── build.gradle.kts     # Root Gradle configuration
└── app/build.gradle.kts # Application module config with Compose, Firebase, OneSignal dependencies
```

## Firebase & OneSignal setup

1. Add your Android `google-services.json` to `CliqueAndroid/app/`.
2. Update `app/src/main/res/values/strings.xml` with the actual OneSignal app id.
3. Set a secure REST API key in `app/build.gradle.kts` via `buildConfigField("String", "ONESIGNAL_REST_KEY", "\"YOUR_KEY\"")`.
4. Optional: create `app/src/main/assets/onesignal_config.json` or store secrets in CI, but never commit production keys.

## Gradle wrapper

The repo ships the wrapper scripts plus `gradle-wrapper.properties`, but **not** the `gradle-wrapper.jar`. Run `gradle wrapper` (or let Android Studio generate it) before building.

## Running the app

```
cd CliqueAndroid
./gradlew assembleDebug   # After the wrapper JAR has been generated
```

Open the module in Android Studio to run on a device/emulator. Phone auth requires a SHA certificate + Firebase console configuration; the test numbers in `FIREBASE_TEST_NUMBERS.md` can be reused.

## Feature coverage

- Passwordless phone login/sign-up flow using Firebase Auth + Compose screens.
- Account completion that persists user metadata identical to `DatabaseManager` on iOS.
- Real-time event/friend/friend-request listeners that mirror the Swift ViewModel logic.
- Event creation, invite management, and friend management screens with the same data contracts.
- OneSignal login/logout + routing hooks so notification payloads deep-link to events/friends tabs.
- Shared utilities (`PhoneNumberFormatter`, country list, badge calculations) ported 1:1 for parity.

Further enhancements (chat, AI event builder, photo uploads, badge automation, etc.) can now be layered on top of this foundation.
