# StarterKit Documentation 📘

This document provides a comprehensive reference for all parameters and configurations in the `StarterKit` plugin.

---

## 🚀 Initialization

**Method**: `StarterKit.initialize()`

Must be called in `main.dart` before `runApp`.

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `iapDataSource` | `IapRemoteDataSource?` | No | `null` | Custom In-App Purchase logic. If null, uses RevenueCat implementation. |
| `adsDataSource` | `AdsRemoteDataSource?` | No | `null` | Custom Ads logic. If null, uses AdMob implementation. |
| `analyticsDataSources` | `List<AnalyticsRemoteDataSource>?` | No | `null` | List of analytics providers (e.g., Firebase, Mixpanel). Default: Firebase. |
| `posthogDataSource` | `PostHogRemoteDataSource?` | No | `null` | Custom PostHog wrapper. Default: Standard PostHog implementation. |
| `supportEmail` | `String?` | No | `'support@example.com'` | Email used for the Feedback service (if Feedback Nest API key is not provided). |
| `feedbackNestApiKey` | `String?` | No | `null` | Feedback Nest API key. If provided, uses Feedback Nest API instead of email. |

**Example:**
```dart
await StarterKit.initialize(
  supportEmail: 'contact@myapp.com',
  // Optional: Swap Ad Provider
  adsDataSource: MyAppLovinDataSource(),
);
```

---

## 🎨 Onboarding

**Method**: `StarterKit.onboarding()`

Returns a `Widget` representing your onboarding flow.

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `pages` | `List<OnboardingPageModel>` | **Yes** | - | list of pages to display. |
| `template` | `OnboardingTemplateType` | No | `standard` | Layout style: `standard`, `minimal`, or `custom`. |
| `onComplete` | `VoidCallback?` | No | `null` | Called when user finishes the last page (e.g., tap "Start"). |
| `onSkip` | `VoidCallback?` | No | `null` | Called when "Skip" button is tapped. Only shows Skip if provided. |
| `onPageChange` | `Function(int)?` | No | `null` | Callback for page swipe events. |
| `activeDotColor` | `Color` | No | `Colors.blue` | Color of the active pagination dot. |
| `nextText` | `String` | No | `'Next'` | Text for the "Next" button. |
| `completeText` | `String` | No | `'Start'` | Text for the "Start" button (last page). |

### `OnboardingPageModel`
| Field | Type | Description |
| :--- | :--- | :--- |
| `title` | `String` | Headline text. |
| `description` | `String` | Body text. |
| `imagePath` | `String?` | Asset path for the main image (Standard template). |
| `customWidget` | `Widget?` | Any widget to render in the center (overrides image). |
| `titleColor` | `Color?` | Custom color for title. |
| `descriptionColor` | `Color?` | Custom color for description. |

---

## ⚙️ Settings

**Method**: `StarterKit.settings()`

Returns a `Widget` representing a generated settings page.

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `sections` | `List<SettingsSection>` | - | Data model defining the list content. |
| `template` | `SettingsTemplateType` | `list` | `list` (flat) or `grouped` (iOS style). |
| `title` | `String` | `'Settings'` | AppBar title. |
| `backgroundColor` | `Color?` | `null` | Custom scaffold background color. |

### `SettingsSection` & `SettingsTile`
*   **`SettingsSection`**: Has a `String? title` and `List<SettingsTile> tiles`.
*   **`SettingsTile`**:
    *   `title` (String): Main text.
    *   `subtitle` (String?): Secondary text.
    *   `icon` (IconData?): Leading icon.
    *   `onTap` (VoidCallback?): Action when tapped.
    *   `trailing` (Widget?): Custom right-side widget (e.g., Switch).

---

## 💸 Ad Revenue & Analytics

**Logic**: The matching of Ads to Analytics is **automated**.

1.  **Events**: When `AdsBloc` detects a paid event (money earned), it emits an internal signal.
2.  **Wiring**: `StarterKit` listens to this and automatically calls `AnalyticsBloc.add(AnalyticsLogAdRevenue(...))`.
3.  **Destinations**:
    *   **Firebase**: Logs `logAdImpression` (Official Google format).
    *   **PostHog**: Logs `ad_revenue` event with properties: `value`, `currency`, `ad_network`, `ad_unit_id`.

**You do not need to manually log ad revenue.**

---

## 📱 Ads

### Ad Types Supported

The StarterKit supports the following ad types:

| Ad Type | Description | Events |
| :--- | :--- | :--- |
| **Banner** | Small ads displayed at the top or bottom of the screen | `AdsLoadBanner` |
| **Interstitial** | Full-screen ads shown between app screens | `AdsLoadInterstitial`, `AdsShowInterstitial` |
| **Rewarded** | Full-screen ads that reward users for watching | `AdsLoadRewarded`, `AdsShowRewarded` |
| **App Open** | Ads shown when the app is opened | `AdsLoadAppOpen`, `AdsShowAppOpen` |
| **Native** | Customizable ads that match your app's design | `AdsLoadNative` |

### App Open Ads

App Open ads are shown when the app is launched or brought to the foreground.

**Load App Open Ad:**
```dart
StarterKit.adsBloc.add(AdsLoadAppOpen(adUnitId: 'ca-app-pub-...'));
```

**Show App Open Ad:**
```dart
StarterKit.adsBloc.add(const AdsShowAppOpen());
```

**Listen for App Open Ad State:**
```dart
BlocListener<AdsBloc, AdsState>(
  listener: (context, state) {
    if (state is AdsShowSuccess && state.type == AdType.appOpen) {
      // App open ad was shown successfully
    }
  },
  child: YourWidget(),
)
```

### Native Ads

Native ads are customizable ads that match your app's design. They require custom widgets to display.

**Load Native Ad:**
```dart
StarterKit.adsBloc.add(AdsLoadNative(adUnitId: 'ca-app-pub-...'));
```

**Use Native Ad Widget:**
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

NativeAdWidget(
  adUnitId: 'ca-app-pub-...',
  factoryId: 'your_factory_id',
)
```

---

## 🔔 Push Notifications (OneSignal)

The StarterKit includes OneSignal push notifications support. Access the push notifications repository through the service locator.

**Initialize OneSignal:**
```dart
final pushRepo = StarterKit.sl<PushNotificationsRepository>();
await pushRepo.initialize('your_onesignal_app_id');
```

**Set User ID:**
```dart
await pushRepo.setUserId('user_123');
```

**Set Email:**
```dart
await pushRepo.setEmail('user@example.com');
```

**Send Tags:**
```dart
// Single tag
await pushRepo.sendTag('user_type', 'premium');

// Multiple tags
await pushRepo.sendTags({
  'user_type': 'premium',
  'subscription': 'monthly',
});
```

**Get Player ID:**
```dart
final result = await pushRepo.getPlayerId();
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (playerId) => print('Player ID: $playerId'),
);
```

**Enable/Disable Notifications:**
```dart
// Enable
await pushRepo.enable();

// Disable
await pushRepo.disable();

// Check if enabled
final result = await pushRepo.isEnabled();
```

---

## 💬 Feedback

The StarterKit supports two feedback methods:

### Email Feedback (Default)

If no Feedback Nest API key is provided, feedback is sent via email:

```dart
await StarterKit.initialize(
  supportEmail: 'support@myapp.com',
);
```

### Feedback Nest API

To use Feedback Nest API, provide your API key during initialization:

```dart
await StarterKit.initialize(
  feedbackNestApiKey: 'your_feedback_nest_api_key',
);
```

**Submit Feedback:**
```dart
final feedbackRepo = StarterKit.sl<FeedbackRepository>();
final result = await feedbackRepo.submitFeedback(
  'This app is amazing!',
  email: 'user@example.com', // Optional
);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (_) => print('Feedback submitted successfully'),
);
```

---

## 📦 Dependency Injection (Advanced)

Access internal blocs and repositories if you need to trigger events manually:

### Blocs
*   `StarterKit.iapBloc` -> `IapBloc`
*   `StarterKit.adsBloc` -> `AdsBloc`
*   `StarterKit.analyticsBloc` -> `AnalyticsBloc`
*   `StarterKit.postHog` -> `PostHogRemoteDataSource?`

### Services (via Service Locator)
*   `StarterKit.sl<RemoteConfigRepository>()` -> Remote Config
*   `StarterKit.sl<GdprRepository>()` -> GDPR
*   `StarterKit.sl<AppRatingRepository>()` -> App Rating
*   `StarterKit.sl<FeedbackRepository>()` -> Feedback
*   `StarterKit.sl<PushNotificationsRepository>()` -> Push Notifications (OneSignal)

**Example: Restore Purchases**
```dart
StarterKit.iapBloc.add(const IapRestorePurchases());
```

**Example: Access Push Notifications Repository**
```dart
final pushRepo = StarterKit.sl<PushNotificationsRepository>();
await pushRepo.initialize('your_onesignal_app_id');
```
