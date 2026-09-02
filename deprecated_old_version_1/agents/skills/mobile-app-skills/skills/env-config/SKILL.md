---
name: env-config
description: How to structure env files, IDE run configs, and use dart-define-from-file for environment-specific builds
---

# Environment & IDE Configuration

## Overview

Every GenRevibes project uses a **compile-time environment variable system** via `--dart-define-from-file`. This provides separate configs for Dev, Release, and Special Dev (Founders) builds without hardcoding secrets or toggling code.

## Architecture

```
project_root/
├── env/
│   ├── dev.json              # Development environment (test ad IDs, debug flags)
│   ├── release.json          # Production environment (real ad IDs, analytics)
│   └── special_dev.json      # Founders/special builds (founders_version = true)
├── env.example.json           # Template for new team members (committed to git)
├── .run/                      # Android Studio run configurations
│   ├── Dev.run.xml
│   ├── Release.run.xml
│   └── Special Dev.run.xml
└── .vscode/                   # VS Code launch configurations
    └── launch.json
```

> **IMPORTANT**: The `env/` folder is `.gitignore`'d. Only `env.example.json` is committed.

## Environment Keys

| Key | Type | Purpose |
|---|---|---|
| `founders_version` | bool | Enables founders-only features |
| `special_version_mode` | bool | Enables special build mode |
| `development_mode` | bool | Enables debug logging, test ads |
| `firebase_api_key_android` | String | Firebase API key for Android |
| `firebase_api_key_ios` | String | Firebase API key for iOS |
| `banner_ad_id` | String | AdMob banner ad unit ID |
| `interstitial_ad_id` | String | AdMob interstitial ad unit ID |
| `app_open_ad_id` | String | AdMob app open ad unit ID |
| `rewarded_ad_id` | String | AdMob rewarded ad unit ID |
| `native_ad_id` | String | AdMob native ad unit ID |
| `one_signal_app_id` | String | OneSignal push notifications app ID |
| `revenue_cat_api_key_android` | String | RevenueCat API key for Android |
| `posthog_api_key` | String | PostHog analytics API key |
| `feed_back_nest_api_key` | String | Feedback Nest API key |

## AdMob IDs

AdMob uses two different ID types and both must be configured by the host app:

- **AdMob App ID**: Native SDK identifier with `~` in the value. Put this in `android/app/src/main/AndroidManifest.xml` as `com.google.android.gms.ads.APPLICATION_ID` and in `ios/Runner/Info.plist` as `GADApplicationIdentifier`.
- **Ad unit IDs**: Placement identifiers with `/` in the value. Put these in env keys such as `banner_ad_id`, `interstitial_ad_id`, `app_open_ad_id`, `rewarded_ad_id`, and `native_ad_id`.

The starter kit ships a Google test AdMob App ID fallback so development builds do not crash before native config exists. Do not ship that fallback. Release builds must override it with the app's own AdMob App ID, and release env files must use this app's own production ad unit IDs.

## Reading Env Vars in Dart

```dart
// Use const String.fromEnvironment for compile-time access
class AppEnv {
  static const bool foundersVersion =
      bool.fromEnvironment('founders_version', defaultValue: false);
  static const bool specialVersionMode =
      bool.fromEnvironment('special_version_mode', defaultValue: false);
  static const bool developmentMode =
      bool.fromEnvironment('development_mode', defaultValue: false);
  static const String firebaseApiKeyAndroid =
      String.fromEnvironment('firebase_api_key_android');
  static const String cloudFunctionsBaseUrl =
      String.fromEnvironment('cloud_functions_base_url');
  // ... all other keys
}
```

## Centralized API Protocol

Every project MUST separate business-level endpoints from low-level network configuration:

- **Business Layer** (`lib/core/api/`): Use `api_endpoints.dart` to centralize all paths and dynamic URL construction logic. Use `api_response.dart` for uniform response modeling.
- **Infrastructure Layer** (`lib/core/network/`): Use for Dio interceptors, connectivity checkers, and low-level HTTP client setup.

**Example `lib/core/api/api_endpoints.dart`**:
```dart
import '../config/app_env.dart';

class ApiEndpoints {
  static const String baseUrl = AppEnv.cloudFunctionsBaseUrl;
  
  static const String transcribe = '$baseUrl/transcribe';
  static const String summarize = '$baseUrl/summarize';
  
  /// Helper for dynamic paths
  static String recordingDetail(String id) => '$baseUrl/recordings/$id';
}
```

## IDE Run Configurations

### Android Studio (`.run/` XMLs)

Each `.run.xml` file uses `--dart-define-from-file` to load the appropriate env file:

```xml
<component name="ProjectRunConfigurationManager">
  <configuration name="Dev" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main.dart" />
    <option name="additionalArgs" value="--dart-define-from-file=env/dev.json" />
  </configuration>
</component>
```

### VS Code (`launch.json`)

```json
{
  "name": "Dev",
  "request": "launch",
  "type": "dart",
  "program": "lib/main.dart",
  "args": ["--dart-define-from-file=env/dev.json"]
}
```

## Setup for New Projects

1. Copy `agents/templates/env/` → `your_project/env/`
2. Copy `agents/templates/.run/` → `your_project/.run/`
3. Copy `agents/templates/.vscode/` → `your_project/.vscode/`
4. Fill in real API keys in `env/dev.json` and `env/release.json`
5. Add `env/` to `.gitignore`
6. Commit `env.example.json` as reference

## Interaction Map

- **Ads** → reads `banner_ad_id`, `interstitial_ad_id`, `app_open_ad_id`, `rewarded_ad_id`, `native_ad_id`
- **Push Notifications** → reads `one_signal_app_id`
- **IAP** → reads `revenue_cat_api_key_android`
- **Analytics** → reads `posthog_api_key`
- **Feedback** → reads `feed_back_nest_api_key`
- **Firebase** → reads `firebase_api_key_android`, `firebase_api_key_ios`
- **Content Locking / Paywall** → reads `founders_version`, `special_version_mode`

## Checklist

- [ ] `env/` folder created with `dev.json`, `release.json`, `special_dev.json`
- [ ] `env.example.json` committed to git
- [ ] `env/` added to `.gitignore`
- [ ] `.run/` configs created for Android Studio
- [ ] `.vscode/launch.json` created for VS Code
- [ ] `AppEnv` class created to read env vars via `String.fromEnvironment`
- [ ] All API keys filled in for dev environment
- [ ] Test IDs used for ads in dev, real IDs in release
- [ ] **AdMob App ID** added to host `AndroidManifest.xml` and `Info.plist`, overriding the starter-kit fallback for release
