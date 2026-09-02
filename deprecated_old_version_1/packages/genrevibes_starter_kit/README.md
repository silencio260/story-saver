# Starter Kit Plugin

A strictly architected, modular plugin system for Flutter apps.

> **Note — dormant in `smart_launcher_app`:** this package is vendored into the
> launcher as the shared exemplar (it is copied across the sibling apps), but the
> launcher host does **not** depend on it: there is no path dependency in the host
> `pubspec.yaml`, no imports, and `StarterKit.initialize()` is never called. That
> is intentional, not an unfinished integration. The package is kept clean and
> correct here so other apps consuming it inherit the fixes.

## Installation

Starter Kit is a **standalone Flutter package** with its own `pubspec.yaml`. Its pub name is `genrevibes_starter_kit` (matching its directory). You can use it as a path dependency or copy the `packages/genrevibes_starter_kit` folder into any project.

### Option 1: Path dependency (in same repo)

If the package lives in `packages/genrevibes_starter_kit` of your project:

```yaml
# pubspec.yaml
dependencies:
  genrevibes_starter_kit:
    path: packages/genrevibes_starter_kit
```

### Option 2: Copy into another project

1. Copy the entire `genrevibes_starter_kit` folder (the one that contains `pubspec.yaml`, `lib/`, etc.) into your project, e.g. `packages/genrevibes_starter_kit` or `plugins/genrevibes_starter_kit`.
2. In your app’s `pubspec.yaml`:

```yaml
dependencies:
  genrevibes_starter_kit:
    path: packages/genrevibes_starter_kit   # or path: plugins/genrevibes_starter_kit
```

3. Run `flutter pub get`.
4. Use in Dart: `import 'package:genrevibes_starter_kit/starter_kit.dart';`

All dependencies (Firebase, AdMob, RevenueCat, etc.) are declared in `genrevibes_starter_kit`’s `pubspec.yaml`; the host app will receive them transitively. Ensure your app’s `android/` and `ios/` are configured for any native SDKs you use (Firebase, OneSignal, etc.).

**If you see "Target of URI doesn't exist" or missing-package errors:** run `flutter pub get` from the **host project root** (the app that depends on `genrevibes_starter_kit`). That resolves the path package and its dependencies.

## Features at a Glance

| Feature | Description | Stack | Swappable? |
| :--- | :--- | :--- | :--- |
| **IAP** | Subscriptions & One-Time Purchases | Bloc + Clean Arch | ✅ (RevenueCat default) |
| **Ads** | Interstitial, Reward, Banner | Bloc + Clean Arch | ✅ (AdMob default) |
| **Analytics** | Unified Event Logging | Bloc (Retention) | ✅ (Firebase default) |
| **PostHog** | Product Analytics | Wrapper | ✅ |
| **Templates** | Onboarding & Settings | Widget Builders | N/A |
| **Services** | Config, Rating, GDPR, Feedback | Repositories | ✅ |

---

## 🚀 Getting Started

### 1. Initialization

In your `main.dart`, initialize the kit before `runApp`.

```dart
await StarterKit.initialize(
  // Optional: Add PostHog
  postHogDataSource: PostHogRemoteDataSourceImpl(), // Or custom
  
  // Optional: Custom Support Email for Feedback
  supportEmail: 'support@myapp.com',
);
```

---

## 🎨 UI Templates

### 1. Onboarding
Create a robust onboarding flow in seconds.

```dart
class MyOnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StarterKit.onboarding(
      template: OnboardingTemplateType.standard, // standard, minimal, or custom
      pages: [
        OnboardingPageModel(
          title: 'Welcome',
          description: 'The best app ever.',
          imagePath: 'assets/welcome.png',
          titleColor: Colors.blue,
        ),
        OnboardingPageModel(
          title: 'Get Started',
          description: 'Sign up now.',
          customWidget: MyCustomHeroWidget(),
        ),
      ],
      onComplete: () {
        // Navigate or save state
        Navigator.of(context).pushReplacementNamed('/home');
      },
      onSkip: () {
        // Handle skip
      },
    );
  }
}
```

### 2. Settings Page
Generate a settings screen dynamically.

```dart
class MySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StarterKit.settings(
      template: SettingsTemplateType.grouped, // list or grouped
      title: 'Preferences',
      sections: [
        SettingsSection(
          title: 'General',
          tiles: [
            SettingsTile(
              title: 'Dark Mode',
              icon: Icons.dark_mode,
              onTap: () { /* Toggle Theme */ },
            ),
            SettingsTile(
              title: 'Language',
              icon: Icons.language,
              subtitle: 'English',
              onTap: () { /* Change Language */ },
            ),
          ],
        ),
        SettingsSection(
          title: 'Account',
          tiles: [
            SettingsTile(
              title: 'Restore Purchases',
              icon: Icons.restore,
              onTap: () { StarterKit.iapBloc.add(const IapRestorePurchases()); },
            ),
            SettingsTile(
              title: 'Privacy Policy',
              icon: Icons.lock,
              onTap: () { /* Open Webview */ },
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 📊 Analytics & PostHog

### 3. Ad Revenue Analytics (Auto-Wired) 💸
To track ad revenue automatically across all providers (Firebase, PostHog, etc.):

1.  **StarterKit handles the wiring**: When you initialize the kit, `AdsBloc` events are automatically piped to `AnalyticsBloc`.
2.  **Firebase**: Logs as `ad_impression` (ROAS ready).
3.  **PostHog**: Logs as `ad_revenue` custom event.

```dart
// No extra code needed! Just initialize properly:
await StarterKit.initialize(
  adsRepository: MyAdsRepository(), // Optional: custom ads impl (AdMob is the default)
  // The kit automatically listens to paid events and logs them!
);
```

### Accessing PostHog
If you initialized PostHog, you can access it safely:

```dart
StarterKit.postHog?.capture(
  eventName: 'video_shared',
  properties: {'platform': 'tiktok'},
);

StarterKit.postHog?.identify(
  userId: 'user_123',
  userProperties: {'plan': 'premium'},
);
```

### Unified Analytics (Firebase + Others)
Use the Bloc for general event logging (goes to Firebase by default).

```dart
StarterKit.analyticsBloc.add(
  const AnalyticsLogEvent(name: 'app_open'),
);
```

---

## 🛠 Feature Reference

### In-App Purchases (IAP)
*   **Bloc**: `StarterKit.iapBloc`
*   **Events**: `IapInitialize`, `IapPurchaseProduct`, `IapRestorePurchases`.
*   **States**: `IapLoading`, `IapInitialized` (contains `SubscriptionStatus`, `products`), `IapError`.

### Ads
*   **Bloc**: `StarterKit.adsBloc`
*   **Events**: `AdsInitialize`, `AdsLoadInterstitial`, `AdsShowInterstitial`.
*   **States**: `AdsReady`, `AdsShowSuccess`, `AdsError`.

### Services
*   **Remote Config**: `StarterKit.sl<RemoteConfigRepository>()`
*   **GDPR**: `StarterKit.sl<GdprRepository>()`
*   **App Rating**: `StarterKit.sl<AppRatingRepository>()`
*   **Feedback**: `StarterKit.sl<FeedbackRepository>()`

---

## 🧩 Dependency Injection
Because `StarterKit` uses `GetIt`, you can inject your own implementations.

**Example: Swapping Analytics Provider**

`initialize()` accepts your own implementations of the feature repositories
(e.g. `analyticsRepository`, `adsRepository`, `iapRepository`, …) plus
`postHogDataSource`, `supportEmail`, and `feedbackNestApiKey`. Pass a repository
to override the default provider:

```dart
class MyAnalyticsRepository implements AnalyticsRepository {
  // ... implementation ...
}

await StarterKit.initialize(
  analyticsRepository: MyAnalyticsRepository(),
);
```
