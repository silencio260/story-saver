---
name: ads
description: Banner, interstitial, rewarded, app open, and native ads via AdMob with starter kit, including ad revenue and ad click tracking
---

# Ads

## Overview

Ads are managed through the starter kit's `AdsBloc`. Supports Banner, Interstitial, Rewarded, App Open, and Native ad types via AdMob. Ad revenue is automatically tracked to Firebase Analytics and Mixpanel/PostHog, and ad clicks must be tracked as the exact `ad_click` event.

## Prerequisites

- Starter kit integrated
- AdMob account + ad unit IDs configured
- Ad IDs in env config (`AppEnv`): `banner_ad_id`, `interstitial_ad_id`, `app_open_ad_id`, `rewarded_ad_id`, `native_ad_id`
- **Mandatory**: AdMob App ID configured in the host app `AndroidManifest.xml` and `Info.plist`.
    - The starter kit includes a Google test App ID only as a fallback so local builds do not crash before the host app is configured.
    - For any real app, especially release/Play Store builds, override the starter-kit default with the app's own AdMob App ID.
    - Android Test App ID: `ca-app-pub-3940256099942544~3347511713`
    - iOS Test App ID: `ca-app-pub-3940256099942544~1458002511`

### Host App AdMob App ID

Add the app's own AdMob App ID to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY" />
    </application>
</manifest>
```

The value with `~` is the AdMob **App ID**, not an ad unit ID. Do not ship the starter kit's default `ca-app-pub-3940256099942544~3347511713`.

Also add the iOS AdMob App ID to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

Ad unit IDs are separate values and must come from the app env config or an app-specific Remote Config setup.

## Implementation

### Load & Show Interstitial

```dart
// Load
StarterKit.adsBloc.add(AdsLoadInterstitial(adUnitId: AppEnv.interstitialAdId));

// Show (after loaded)
StarterKit.adsBloc.add(const AdsShowInterstitial());
```

### Load & Show Rewarded

```dart
StarterKit.adsBloc.add(AdsLoadRewarded(adUnitId: AppEnv.rewardedAdId));
StarterKit.adsBloc.add(const AdsShowRewarded());
```

### Banner Ad Widget

```dart
StarterKit.bannerAd(adUnitId: AppEnv.bannerAdId)
```

### Native Ad Widget

```dart
StarterKit.nativeAd(adUnitId: AppEnv.nativeAdId)
```

### App Open Ad

```dart
StarterKit.adsBloc.add(AdsLoadAppOpen(adUnitId: AppEnv.appOpenAdId));
StarterKit.adsBloc.add(const AdsShowAppOpen());
```

### AdMob IDs Management
- **Test IDs**: During development, use Google's [Test Ad Unit IDs](https://developers.google.com/admob/android/test-ads#sample_ad_units).
- **Production IDs**: Ensure real AdMob IDs are injected via the `EnvConfig` for production builds.
- **App ID vs Unit IDs**: The platform AdMob App ID belongs in Android/iOS native config. Banner, interstitial, app-open, rewarded, and native ad unit IDs belong in `AppEnv` or Remote Config and are passed into the starter kit APIs.
- **Starter Kit Defaults**: Treat any starter-kit/default Google sample ID as development-only. Host apps must provide their own production App ID and ad unit IDs.
- **Remote Config**: Ad IDs can also be dynamically managed via Remote Config for easier updates without app store releases.

### AdsBloc Usage
The `AdsBloc` is the central hub for all ad-related actions.

```dart
// Check if ads are enabled (hidden for premium)
final adsEnabled = context.read<AdsBloc>().state.isEnabled;

// Load an interstitial
context.read<AdsBloc>().add(AdsLoadInterstitial(adUnitId: AppEnv.interstitialAdId));

// Show an interstitial (e.g., after a chat session ends)
if (adsEnabled) {
  context.read<AdsBloc>().add(const AdsShowInterstitial());
}
```

### Disable Ads for Subscribers
The `starter_kit` handles this automatically if `IapBloc` and `AdsBloc` are correctly configured. When the `IapState` becomes `isActive`, the `AdsBloc` state is updated to `isEnabled: false`.

## Analytics Contract

Ads must emit these standard events:

| Event | Destination | Trigger |
|---|---|---|
| `ad_impression` | Firebase | AdMob `onPaidEvent` routed through `FirebaseAnalytics.logAdImpression`. |
| `ad_revenue` | Mixpanel/PostHog | Same AdMob `onPaidEvent` routed as a custom revenue event. |
| `ad_click` | Firebase + Mixpanel/PostHog | AdMob `onAdClicked` for banner/native and `FullScreenContentCallback.onAdClicked` for interstitial/rewarded/app-open. |
| `ad_lifecycle` | Firebase + Mixpanel/PostHog | Dev/test lifecycle events such as load/show success/failure when the host app exposes a developer ads test screen. |

Required `ad_click` params:

```dart
{'ad_type': 'banner' | 'native' | 'interstitial' | 'rewarded' | 'app_open'}
```

Implementation rules:

- `AdsRepository` should expose click listener/recording methods so all ad surfaces use one path.
- Banner/native widgets should call `recordAdClick('banner')` or `recordAdClick('native')` from `onAdClicked`.
- Interstitial, rewarded, and app-open ads should call the click listener from `FullScreenContentCallback.onAdClicked`.
- Keep `ad_lifecycle` separate from `ad_click`; lifecycle is useful for developer testing, but dashboards often need the exact `ad_click` event name.
- Test ads can fire callbacks, but normal Firebase/AdMob revenue dashboards may not show test revenue like production. Verify with Firebase DebugView and Mixpanel live events.

## Interaction Map

- **IAP** → Subscribers see no ads
- **Analytics** → Ad revenue auto-tracked (Firebase `ad_impression` + Mixpanel/PostHog `ad_revenue`) and ad clicks tracked as `ad_click`
- **Tracking** → Adjust ad frequency by engagement level
- **Content Locking** → Show rewarded ads to unlock content

## Checklist

- [ ] Ad unit IDs in env config (test IDs for dev, real for release)
- [ ] Host Android `AndroidManifest.xml` overrides the starter-kit AdMob test App ID with this app's real AdMob App ID for release
- [ ] Host iOS `Info.plist` contains this app's real `GADApplicationIdentifier` for release
- [ ] `AdsBloc` provided in widget tree
- [ ] Interstitial ads load on appropriate screens
- [ ] Rewarded ads offered for content unlock
- [ ] Banner ads placed in layouts
- [ ] Ads disabled for subscribers
- [ ] `ad_impression` verified in Firebase DebugView after paid callbacks
- [ ] `ad_revenue` verified in Mixpanel/PostHog live events if configured
- [ ] `ad_click` verified for each ad type that can be clicked
