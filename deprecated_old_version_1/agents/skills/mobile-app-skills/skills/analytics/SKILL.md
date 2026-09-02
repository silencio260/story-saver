---
name: analytics
description: Firebase Analytics, Mixpanel/PostHog, Crashlytics, automatic Firebase event mirrors, and unified event logging via starter kit
---

# Analytics

## Overview

Analytics provides unified event logging to Firebase Analytics and Mixpanel/PostHog, plus Crashlytics for crash reporting. The starter kit handles shared wiring for app events, retention, ad revenue, and ad clicks.

## Prerequisites

- Starter kit integrated
- Mixpanel token or PostHog key in env config, depending on the app
- Firebase project configured

## Firebase dependencies must be direct (version-locked to the kit)

The starter kit consumes `firebase_analytics` (and `firebase_core` / `firebase_crashlytics`) internally, so an app can *appear* to build without listing them — they leak in transitively through the kit's path dependency. **Do not rely on this.** A kit refactor or dependency bump can silently drop the transitive edge and break the app's analytics build with a confusing error.

Always declare them as **direct** dependencies in the app's `pubspec.yaml`, and **pin the version to match the kit's constraint** so the two never resolve to incompatible majors:

```yaml
dependencies:
  genrevibes_starter_kit:
    path: packages/genrevibes_starter_kit
  firebase_core: ^3.6.0
  firebase_crashlytics: ^4.1.3
  firebase_analytics: ^11.0.0 # aligned with genrevibes_starter_kit (must match its firebase_analytics constraint)
```

> Rule of thumb: any package the app imports directly **or** depends on through the kit's public surface (Firebase, `get_it`, `permission_handler`, …) should be a direct dependency whose version is kept in lockstep with the kit's `pubspec.yaml`. Check `packages/genrevibes_starter_kit/pubspec.yaml` for the authoritative constraint before pinning.

## Implementation

### Log Events

```dart
// General event
StarterKit.analyticsBloc.add(const AnalyticsLogEvent(name: 'feature_used'));

// Event with parameters
StarterKit.analyticsBloc.add(AnalyticsLogEvent(
  name: 'button_clicked',
  parameters: {'button_name': 'subscribe', 'screen': 'home'},
));

// Retention event (auto-handled by tracking system)
StarterKit.analyticsBloc.add(AnalyticsLogRetention(name: 'app_opened'));
```

### Mixpanel / PostHog

```dart
StarterKit.mixpanel?.capture(eventName: 'video_shared', properties: {'platform': 'tiktok'});
StarterKit.postHog?.capture(eventName: 'video_shared', properties: {'platform': 'tiktok'});
StarterKit.postHog?.identify(userId: 'user_123', userProperties: {'plan': 'premium'});
```

### Ad Revenue (Auto-Wired)

No extra code needed after ads are initialized correctly. AdMob paid callbacks must flow into the starter kit `AdsRepository` paid-event listener.

- Firebase receives ad revenue through `FirebaseAnalytics.logAdImpression`, so the Firebase event name is `ad_impression`.
- Mixpanel receives the same paid callback as `ad_revenue`.
- Test ads may not populate normal Firebase/AdMob revenue dashboards like production ads; use Firebase DebugView and Mixpanel live events while developing.

### Ad Clicks (Auto-Wired)

Ad click callbacks must emit the exact `ad_click` event to Firebase and Mixpanel/PostHog with:

```dart
{'ad_type': 'banner' | 'native' | 'interstitial' | 'rewarded' | 'app_open'}
```

Banner/native widgets should call `AdsRepository.recordAdClick(...)` from `onAdClicked`. Full-screen ads should call the repository click listener from `FullScreenContentCallback.onAdClicked`.

## Standard Event Contract

When a user asks to add "the standard Firebase/Mixpanel events" or refers to the Firebase dashboard event list, keep this contract:

| Event | Firebase | Mixpanel/PostHog | Implementation rule |
|---|---|---|---|
| `screen_view` | Use `logScreenView` | Mirror as `screen_view` | Route observer or explicit screen logger. |
| `app_open` | Custom app event | Custom app event | Log on every launch after analytics init. |
| `first_open` | Firebase automatic | Mirror once if needed | Do not fake duplicate Firebase automatic event; mirror to Mixpanel/PostHog on first retained open. |
| `session_start` | Firebase automatic | Optional custom mirror | Prefer app-specific `retention_session_started` unless exact mirror is requested. |
| `user_engagement` | Firebase automatic | Optional custom mirror | Usually leave Firebase-only unless product analytics needs a custom engagement event. |
| `app_remove` | Firebase automatic uninstall signal | Not client-side trackable after uninstall | Cannot be emitted by app code after uninstall; Mixpanel requires backend/push-provider uninstall detection. |
| `ad_impression` | `logAdImpression` | Usually `ad_revenue` | Firebase event name is `ad_impression`; Mixpanel revenue event is `ad_revenue`. |
| `ad_revenue` | Not the Firebase event name | Custom Mixpanel/PostHog event | Fired from AdMob `onPaidEvent`. |
| `ad_click` | Custom event | Custom event | Fired from AdMob click callbacks. |
| `notification_receive` | Firebase/FCM automatic only if FCM is integrated | Custom mirror if implemented | Do not claim this exists unless push notification handling is wired. |
| `in_app_purchase` / subscription renewals | Provider/Firebase integration dependent | Custom mirror if IAP provider wired | Do not claim this exists without real IAP purchase/renewal callbacks. |

For launcher apps that observe other apps being installed or removed, track privacy-safe app-management events without package names:

```dart
app_install_event: {event_type: 'added' | 'removed' | 'updated', source: 'package_broadcast'}
installed_app_removed: {source: 'package_broadcast'}
```

These are not the same as Firebase's automatic `app_remove`, which means this app itself was removed.

## ProGuard / R8 (Android)

To prevent PostHog classes from being stripped during release builds, keep rules are required. While the `starter_kit` package provides these automatically via `consumerProguardFiles`, it is **highly recommended** to also include them in your app's `android/app/proguard-rules.pro` for redundancy and visibility.

1. Ensure `minifyEnabled true` is set in your app's `build.gradle`.
2. Add the following to your app's `proguard-rules.pro`:

```proguard
# PostHog Proguard Rules
-keep class com.posthog.flutter.** { *; }
-keep class com.posthog.** { *; }
```

## Verifying Events Are Logging

A common confusion: "I added events but the dashboard is empty." This is almost always because the **standard Firebase Analytics reports are not real-time** — they are not broken.

### Why DebugView and production reports differ

Firebase Analytics is built for production telemetry at scale, so on-device it **batches** events and uploads them in bundles (roughly once an hour, and on app background) to save battery and data. The standard **Analytics → Events / Dashboard** reports then run their own aggregation pass on top of that, so newly-logged events typically take **several hours up to ~24h** to appear. This is the correct production behavior — you should never gate a release on "I saw it in the dashboard immediately."

**DebugView** is the opposite: when a device is flagged as a debug device, the SDK switches off batching and streams every event to Firebase **immediately**, tagged to that one device. It exists specifically so you can confirm wiring during development without waiting for the production pipeline.

| | DebugView | Standard reports (Events/Dashboard) |
|---|---|---|
| Latency | Seconds (live stream) | Hours to ~24h |
| Batching | Off (one event at a time) | On (hourly + on background) |
| Scope | Only debug-flagged devices | All users, aggregated |
| Use for | Confirming events fire during dev | Real product analytics |

> Mixpanel works the same way conceptually, but its **Events / Activity feed is already near-real-time** per distinct ID — no debug flag needed. The bigger Mixpanel gotcha is the `mixpanel_token` / `MIXPANEL_TOKEN` env value: with no token the SDK is a silent no-op and nothing logs, debug or not. Firebase needs no token — it authenticates via `google-services.json` / `firebase_options.dart`.

### Enable Firebase DebugView

DebugView is keyed off a device-level property, not a code change, so no rebuild is needed.

**Android** (replace the package with your app's `applicationId`):

```bash
# Turn ON debug mode for this app
adb shell setprop debug.firebase.analytics.app com.your.package.name

# Turn OFF when done
adb shell setprop debug.firebase.analytics.app .none.
```

**iOS** — add the launch argument `-FIRDebugEnabled` in Xcode (Product → Scheme → Edit Scheme → Run → Arguments). Use `-FIRDebugDisabled` to turn it off.

Then:

1. Open Firebase console → your project → **Analytics → DebugView**.
2. Launch the app on the flagged device.
3. Watch events stream in within seconds — `app_open` and `screen_view` fire on startup, then anything you trigger (open drawer, search, settings, etc.).

For a coarser real-time check that needs no setup, **Analytics → Realtime** shows the last 30 minutes across all users.

## Interaction Map

- **Ads** → Ad revenue auto-tracked
- **Tracking** → Retention events flow through analytics
- **IAP** → Purchase events logged
- **All features** → Should log key user actions

## Checklist

- [ ] `firebase_analytics` (+ `firebase_core`/`firebase_crashlytics`) are **direct** deps, version-aligned to the kit (not relied on transitively)
- [ ] `AnalyticsBloc` provided in widget tree
- [ ] Key user actions logged as events
- [ ] Mixpanel token/distinct id supplied to `StarterKit.initialize` before startup events if those events must appear in Mixpanel
- [ ] Firebase automatic events that Mixpanel does not track by itself are either intentionally Firebase-only or explicitly mirrored
- [ ] Events verified live in Firebase **DebugView** (not the delayed standard reports)
- [ ] Crashlytics receiving crash reports
