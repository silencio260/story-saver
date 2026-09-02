---
name: tracking-retention
description: RetentionTracker, UserTargetingManager, D0/D1/D3/D7/D10/D15/D20/D25/D30 milestones, first five opens/sessions, user segmentation, and engagement analytics
---

# Tracking & Retention

## Overview

The starter kit includes a comprehensive user tracking and retention system mirrored from the Status Saver template. It automatically tracks app opens, sessions, daily active days, first-five open/session milestones, and retention milestones (D0, D1, D3, D7, D10, D15, D20, D25, D30). It also provides user segmentation for targeted offers.

## Prerequisites

- Starter Kit integrated (see `starter-kit/SKILL.md`)
- Analytics initialized (see `skills/analytics/SKILL.md`)
- `LocalStorage` initialized in starter kit core

## Architecture

The tracking system lives entirely in the starter kit:

```
starter_kit/lib/features/analytics/domain/services/
├── analytics_service.dart         # Unified analytics facade
├── retention_tracker.dart         # Core retention tracking (singleton)
└── user_targeting_manager.dart    # User segmentation (singleton)

starter_kit/lib/features/analytics/domain/utils/
└── analytics_names.dart           # Event name constants
```

## Components

### RetentionTracker

Singleton that tracks:
- **First install date** — When the app was first opened
- **Last open date** — Most recent app open
- **Total app opens** — Lifetime open count
- **Session timestamps** — Every session start
- **Daily open dates** — Unique days the app was opened

**Key Methods:**

| Method | Returns | Description |
|---|---|---|
| `trackAppOpen(analytics)` | `Future<void>` | Called automatically by `StarterKit.initialize` unless `autoTrackAppOpen: false` |
| `trackSession(analytics)` | `Future<void>` | Call on app resume from background if session-resume analytics are required |
| `getTotalAppOpens()` | `int` | Lifetime opens |
| `getSessionCountToday()` | `int` | Sessions in current day |
| `getDaysSinceInstall()` | `int` | Days since first install |
| `getDaysSinceLastOpen()` | `int` | Days since last open |
| `getActiveDays()` | `List<String>` | List of active day dates |
| `hasReturnedOnDay(day)` | `bool` | Whether user opened on day N |
| `getD7RetentionRate()` | `double` | 7-day retention percentage |
| `getEngagementMetrics()` | `Map` | All metrics as a map |

**Automatic Events Logged:**

| Event | Trigger |
|---|---|
| `retention_app_opened` | Every `trackAppOpen()` call |
| `retention_session_started` | Every `trackSession()` call |
| `retention_first_open` | First retained app open |
| `retention_second_open` | Second retained app open |
| `retention_third_open` | Third retained app open |
| `retention_fourth_open` | Fourth retained app open |
| `retention_fifth_open` | Fifth retained app open |
| `retention_first_session` | First retained session |
| `retention_second_session` | Second retained session |
| `retention_third_session` | Third retained session |
| `retention_fourth_session` | Fourth retained session |
| `retention_fifth_session` | Fifth retained session |
| `retention_day_0_returned` | User opens app on install day / day 0 |
| `retention_day_1_returned` | User opens app on day 1 after install |
| `retention_day_3_returned` | User opens app on day 3 after install |
| `retention_day_7_returned` | User opens app on day 7 after install |
| `retention_day_10_returned` | User opens app on day 10 after install |
| `retention_day_15_returned` | User opens app on day 15 after install |
| `retention_day_20_returned` | User opens app on day 20 after install |
| `retention_day_25_returned` | User opens app on day 25 after install |
| `retention_day_30_returned` | User opens app on day 30 after install |

### Firebase Automatic Event Mirrors

Firebase automatically logs `first_open`; Mixpanel/PostHog do not. `StarterKit.initialize` should mirror it once when `RetentionTracker.getTotalAppOpens() == 1` after automatic `trackAppOpen(...)` completes.

Do not create a fake Firebase `first_open` event with app code. Firebase already owns that automatic event name.

Firebase also infers `app_remove` when this app is uninstalled. The app cannot emit an uninstall event after it has been removed. For Mixpanel/PostHog, use backend or push-provider uninstall detection if that signal is required.

### UserTargetingManager

Segmentation logic using RetentionTracker data:

**Engagement Levels:**
- `FIRST_TIME` — First session ever
- `LOW` — <3 days active or <5 total opens
- `MEDIUM` — 3-6 days active or 5-15 opens
- `HIGH` — 7-20 days active or 15-50 opens
- `POWER_USER` — 20+ days active or 50+ opens

**Key Methods:**

| Method | Returns | Description |
|---|---|---|
| `startTracking(analytics)` | `Future<void>` | Initialize and begin tracking |
| `isFirstTimeUser()` | `bool` | Only 1 open ever |
| `isNewUser()` | `bool` | Installed < 7 days ago |
| `isReturningUser()` | `bool` | More than 1 open |
| `isLoyalUser()` | `bool` | 7+ active days |
| `isPowerUser()` | `bool` | 20+ active days or 50+ opens |
| `getEngagementLevel()` | `UserEngagementLevel` | Current engagement tier |
| `getUserSegment()` | `String` | Segment label |
| `getUserProfile()` | `Map` | Full profile map for analytics |
| `logUserSegment()` | `Future<void>` | Log segment to analytics |
| `logOfferShown(type)` | `Future<void>` | Log when offer shown to user |

## Implementation

### Initialize in main.dart

```dart
void main() async {
  // ... Firebase + StarterKit init ...

  await StarterKit.initialize(
    analyticsUserId: installId,
    mixpanelToken: AppEnv.mixpanelToken,
    mixpanelDistinctId: installId,
  );

  runApp(const MyApp());
}
```

Do not call `RetentionTracker.trackAppOpen(...)` or `UserTargetingManager.startTracking(...)` separately for startup tracking unless `autoTrackAppOpen: false` is set and the host app intentionally owns the lifecycle.

### Use for Targeted Features

```dart
// Show paywall only to returning non-subscribers
final targeting = UserTargetingManager.instance;
if (targeting.isReturningUser() && !isSubscribed) {
  showPaywall();
}

// Show special offer to loyal users
if (targeting.isLoyalUser()) {
  showLoyaltyReward();
  targeting.logOfferShown('loyalty_reward');
}

// Adjust ad frequency by engagement
final level = targeting.getEngagementLevel();
if (level == UserEngagementLevel.POWER_USER) {
  // Fewer ads for power users
} else if (level == UserEngagementLevel.LOW) {
  // More aggressive monetization
}
```

## Interaction Map

- **Analytics** → All retention events flow through `AnalyticsService` to Firebase + Mixpanel/PostHog
- **Ads** → Use engagement level to adjust ad frequency
- **Paywall / IAP** → Use user segment to target offers
- **Onboarding** → `isFirstTimeUser()` determines whether to show onboarding
- **Push Notifications** → Segment tags for targeted notifications
- **Remote Config** → Can combine with remote config for A/B testing

## Checklist

- [ ] `StarterKit.initialize` receives `analyticsUserId` and Mixpanel config when Mixpanel startup events are required
- [ ] Analytics service properly initialized
- [ ] Retention events appearing in Firebase DebugView and Mixpanel/PostHog live events when configured
- [ ] `first_open` is mirrored only outside Firebase if the exact event name is required
- [ ] `app_remove` is treated as Firebase automatic / backend-only, not client-side app code
- [ ] User segments logged on app open
- [ ] Targeting logic integrated with paywall/ads decisions
