---
name: app-rename
description: Change the app's display name, iOS bundle identifier, and Android package/applicationId using the rename and change_app_package_name Flutter packages — with launcher-specific safeguards. For icons/splash see the App Branding & Assets skill.
---

# App Rename (Name, Bundle ID & Package)

This skill covers changing **what the app is called and how it is identified**:

| What | Where it lives | Tool |
|---|---|---|
| **Display name** (under the launcher icon, in Settings) | Android `android:label`, iOS `CFBundleDisplayName` | `rename` package |
| **iOS bundle identifier** | Xcode build settings / `PRODUCT_BUNDLE_IDENTIFIER` | `rename` package |
| **Android package / applicationId** | `namespace` + `applicationId` in `build.gradle.kts`, Kotlin folder tree, `AndroidManifest.xml` | `change_app_package_name` package |
| **App icon / splash** | — | See the **App Branding & Assets** skill (uses `flutter_launcher_icons`) — not covered here |

> The three identifiers are independent. Renaming the **display name** is trivial and reversible. Renaming the **package / bundle id** is high-risk and, for a published app, effectively permanent — read the ⚠️ section before touching it.

---

## 1. Display name (safe, reversible)

The display name is what users see under the launcher icon and in system settings. Changing it does **not** affect the package, signing, or store identity.

### Option A — `rename` package (cross-platform, recommended)

[`rename`](https://pub.dev/packages/rename) updates the name (and bundle id) across Android + iOS in one command.

```bash
dart pub global activate rename

# Inspect current values first
rename getAppName --targets ios,android

# Set the new display name
rename setAppName --targets ios,android --value "Simple Home Screen Launcher"
```

> ⚠️ `rename` (>= 3.0.0) uses the `getAppName` / `setAppName` sub-command syntax above. Older snippets online use `flutter pub run rename --appname "..."` — that API is deprecated. If a command errors, check the installed version with `rename --version` and read `rename --help`.

### Option B — manual edit (most control, this repo's preference)

For this project the manual edit is often **safer than `rename`**, because the Android manifest contains several `android:label` entries for the mini-app activity-aliases (Clock, App Locker, App Hider, etc.) and you only want to touch the main application label — not the aliases. (See the **App Hider disguise** notes: alias labels are part of the disguise system, do not rename them.)

- **Android** — `android/app/src/main/AndroidManifest.xml`, the `android:label` on the `<application>` tag only:
  ```xml
  <application android:label="Simple Home Screen Launcher" ...>
  ```
  `MainActivity` has no own label, so it inherits this. Leave every other `android:label` (the `<activity-alias>` entries and service labels) untouched.

- **iOS** — `ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleDisplayName</key>
  <string>Simple Home Screen Launcher</string>
  ```
  (`CFBundleName` is the short internal name, max 15 chars; usually leave it.)

After editing, run `flutter clean` so the manifest/plist change is picked up on the next build.

---

## 2. iOS bundle identifier

```bash
rename getBundleId --targets ios
rename setBundleId --targets ios --value "com.genrevibes.simplelauncher"
```

Changing the bundle id detaches the build from its existing App Store record, push certificates, and any iOS Firebase config (`GoogleService-Info.plist`). Only do this before first submission, or when intentionally creating a new app identity.

---

## 3. Android package / applicationId  ⚠️ HIGH RISK

Use [`change_app_package_name`](https://pub.dev/packages/change_app_package_name) — it rewrites `namespace` + `applicationId` in `build.gradle.kts`, the `package` in `AndroidManifest.xml`, and moves the `MainActivity` Kotlin folder tree.

```bash
flutter pub run change_app_package_name:main com.genrevibes.simplelauncher
# (or:  dart run change_app_package_name:main com.genrevibes.simplelauncher )
```

### ⚠️ Before you run it — read all of this

1. **A published app's package can NEVER change.** Google Play ties the listing, install base, reviews, and update path to the `applicationId`. Renaming the package ships a *different app*. Only rename **before first Play release**.

2. **`change_app_package_name` only moves `MainActivity`.** This project has additional native classes — `AppLockBiometricActivity`, the alarm/ring native Kotlin, the import trampoline activity, the `SmartLauncherApplication` class — under the old package. After running the tool, **grep the native side** and fix any stragglers:
   ```bash
   grep -rn "com.smartphonelauncherapp" android/app/src/main/kotlin android/app/src/main/AndroidManifest.xml
   ```
   Move/repackage any remaining Kotlin files and update their `package` declarations and manifest `android:name` references.

3. **Firebase / Google Services break.** `google-services.json` is keyed by package name. You must register the new package in the Firebase console, download a fresh `google-services.json`, and replace `android/app/google-services.json`. Analytics (Firebase + Mixpanel) and Crashlytics will not report until this is done. (See the **Analytics** and **Firebase Infrastructure** skills.)

4. **AdMob, deep links, and any hardcoded package strings** — search Dart and native for the old package id and any `applicationId`-derived intents/authorities (e.g. FileProvider authorities `${applicationId}.provider`).

5. **Signing is unaffected by the rename itself**, but the Play upload identity is — see the **Android Production Signing** skill.

### What package rename does NOT change

- **pubspec `name:`** (e.g. `smart_launcher_app`) is the Dart package name used by every `import 'package:smart_launcher_app/...'`. Neither `rename` nor `change_app_package_name` touches it. Changing it means rewriting every import — generally not worth it and unrelated to the user-facing name.

---

## Quick recipe — "just rename the app"

If the user only wants a new **display name** (the common case):

1. Edit the single `<application android:label="...">` in `AndroidManifest.xml`.
2. Edit `CFBundleDisplayName` in iOS `Info.plist`.
3. `flutter clean`, hand back to the user to rebuild/install.

Do **not** touch the package/applicationId or bundle id unless the user explicitly asks and confirms the app is not yet published.
