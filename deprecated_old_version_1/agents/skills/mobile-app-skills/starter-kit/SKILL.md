---
name: starter-kit
description: How to integrate and configure the GenRevibes Starter Kit package into any Flutter project
---

# Starter Kit Integration

## Overview

The Starter Kit is a **standalone Flutter package** (`packages/starter_kit/`) providing production-ready, modular features that plug into any Clean Architecture Flutter app. It uses its own `GetIt` service locator internally and exposes a single `StarterKit` facade class.

## Prerequisites

- Flutter 3.7.0+
- Firebase project configured (for Analytics, Crashlytics, Remote Config)
- `env/` configuration files set up (see `skills/env-config/SKILL.md`)

## Installation

### 1. Add Path Dependency

```yaml
# pubspec.yaml
dependencies:
  starter_kit:
    path: packages/starter_kit
```

### 2. Run pub get

```bash
flutter pub get
```

All transitive dependencies (Firebase, AdMob, RevenueCat, OneSignal, PostHog, etc.) are resolved automatically.

## Initialization

In `main.dart`, initialize **before** `runApp`:

```dart
import 'package:starter_kit/starter_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await StarterKit.initialize(
    supportEmail: 'support@yourapp.com',
    analyticsUserId: installId,
    mixpanelToken: AppEnv.mixpanelToken,
    mixpanelDistinctId: installId,
    // Optional overrides:
    // feedbackNestApiKey: 'YOUR_KEY',
    // adsDataSource: MyCustomAdsDataSource(),
    // analyticsDataSources: [MyMixpanelDataSource()],
    // postHogDataSource: PostHogRemoteDataSourceImpl(),
    // authRepository: MyCustomAuthRepository(),
    // userProfileRepository: MyCustomUserProfileRepository(),
    // iapRepository: MyCustomIapRepository(),
  );

  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}
```

`StarterKit.initialize` owns startup analytics by default:

- Initializes Mixpanel before startup events when `mixpanelToken` and `mixpanelDistinctId` are supplied.
- Sets the analytics user id when `analyticsUserId` is supplied.
- Logs `app_open`.
- Calls `RetentionTracker.trackAppOpen(...)`, including D0 and first-five open/session milestones.
- Mirrors Firebase automatic `first_open` to Mixpanel once.

Do not add separate manual calls for `StarterKit.analytics.setUserId`, `AppAnalytics.appOpen`, `StarterKit.retentionTracker.trackAppOpen`, or `mixpanel.capture('first_open')` unless `autoTrackAppOpen: false` is explicitly used.

## Available Features

| Feature | Access Pattern | Skill File |
|---|---|---|
| **IAP** | `StarterKit.iapBloc` | `skills/iap/SKILL.md` |
| **Ads** | `StarterKit.adsBloc` | `skills/ads/SKILL.md` |
| **Analytics** | `StarterKit.analyticsBloc` | `skills/analytics/SKILL.md` |
| **PostHog** | `StarterKit.postHog` | `skills/analytics/SKILL.md` |
| **Retention** | `StarterKit.retentionTracker` | `skills/tracking-retention/SKILL.md` |
| **Remote Config** | `StarterKit.sl<RemoteConfigRepository>()` | `skills/remote-config/SKILL.md` |
| **GDPR** | `StarterKit.sl<GdprRepository>()` | `skills/gdpr-compliance/SKILL.md` |
| **App Rating** | `StarterKit.sl<AppRatingRepository>()` | `skills/app-rating/SKILL.md` |
| **Feedback** | `StarterKit.sl<FeedbackRepository>()` | `skills/feedback/SKILL.md` |
| **Push Notifications** | `StarterKit.sl<PushNotificationsRepository>()` | `skills/push-notifications/SKILL.md` |

## Remote Config Template

When the user asks for a "remote config temp", "remote config template", or Firebase Remote Config template, use the canonical template documented in `skills/remote-config/SKILL.md`:

```text
skills/remote-config/remote_config_template.json
```

This template is the starter Firebase Remote Config JSON for app ad timing, rewarded/interstitial/banner intervals, and app-open ad toggles.

## AdMob Host Configuration

The starter kit includes a Google test AdMob App ID in its Android manifest only as a safety fallback. Every host app must override that default before release:

- Add this app's own AdMob App ID to `android/app/src/main/AndroidManifest.xml` as `com.google.android.gms.ads.APPLICATION_ID`.
- Add this app's own AdMob App ID to `ios/Runner/Info.plist` as `GADApplicationIdentifier`.
- Put this app's own banner/interstitial/app-open/rewarded/native ad unit IDs in env config or app-specific Remote Config.

Do not confuse the App ID (`ca-app-pub-...~...`) with ad unit IDs (`ca-app-pub-.../...`). Do not ship the starter-kit Google sample IDs.

## UI Templates

### Onboarding

```dart
StarterKit.onboarding(
  pages: [...],
  onComplete: () => Navigator.pushReplacementNamed(context, '/home'),
  onSkip: () => Navigator.pushReplacementNamed(context, '/home'),
);
```

### Settings

```dart
StarterKit.settings(
  template: SettingsTemplateType.grouped,
  sections: [...],
);
```

### Banner Ads

```dart
StarterKit.bannerAd(adUnitId: 'ca-app-pub-...');
```

### Native Ads

```dart
StarterKit.nativeAd(adUnitId: 'ca-app-pub-...');
```

### PostHog Wrapper

```dart
StarterKit.postHogWrapper(
  apiKey: 'phc_...',
  child: MyApp(),
);
```

### Double Tap to Exit

```dart
StarterKit.doubleTapToExit(child: HomeScreen());
```

## Swapping Providers

The starter kit is designed to be provider-agnostic. You can swap any default implementation:

```dart
// Custom ads provider (e.g., AppLovin instead of AdMob)
await StarterKit.initialize(
  adsDataSource: MyAppLovinDataSource(),
);

// Custom analytics (e.g., Mixpanel instead of Firebase)
await StarterKit.initialize(
  analyticsDataSources: [MyMixpanelDataSource()],
);
```

## DI Wiring Between App and Starter Kit

The starter kit uses its own `GetIt` instance (`StarterKit.sl`). Your app uses the main `sl` from `container_injector.dart`. They are **separate** — do not register app dependencies in the starter kit or vice versa.

To pass starter kit blocs to your widget tree, provide them in `my_app.dart`:

```dart
MultiBlocProvider(
  providers: [
    // App blocs
    BlocProvider(create: (_) => sl<YourFeatureBloc>()),
    // Starter kit blocs
    BlocProvider.value(value: StarterKit.iapBloc),
    BlocProvider.value(value: StarterKit.adsBloc),
    BlocProvider.value(value: StarterKit.analyticsBloc),
  ],
  child: MaterialApp(...),
);
```

## API & Network with Starter Kit

The Starter Kit manages its own internal network traffic for Ads, IAP, and Analytics. However, your app’s custom backend logic (Cloud Functions) MUST follow the centralized API pattern:

- **APP Logic**: All custom backend calls MUST use `lib/core/api/api_endpoints.dart`.
- **KIT Logic**: Use the `StarterKit` facade for all kit-provided features.
- **Interceptors**: Common network headers (Auth tokens, Language) should be handled in `lib/core/network/` logic, but never hardcoded in the Starter Kit calls.

## Checklist

- [ ] `starter_kit` added as path dependency in `pubspec.yaml`
- [ ] `StarterKit.initialize()` called in `main.dart` before `runApp`
- [ ] Firebase initialized before StarterKit
- [ ] Starter kit blocs provided in `MultiBlocProvider`
- [ ] Startup analytics configured through `StarterKit.initialize` (`analyticsUserId`, `mixpanelToken`, `mixpanelDistinctId` when needed)
- [ ] Env keys configured for all required services
- [ ] Android/iOS platform configs set for native SDKs (Firebase, AdMob, OneSignal)
- [ ] Host app overrides starter-kit AdMob defaults with its own AdMob App ID and production ad unit IDs for release
