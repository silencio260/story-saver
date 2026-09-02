---
name: push-notifications
description: OneSignal push notifications with user targeting, tags, and segmentation
---

# Push Notifications

## Overview

Push notifications use OneSignal via the starter kit's `PushNotificationsRepository`. Supports user targeting, tagging, and enable/disable functionality.

## Prerequisites

- Starter kit integrated
- `one_signal_app_id` in env config
- OneSignal dashboard configured
- Platform configs (APNs for iOS, FCM for Android)

## Implementation

```dart
final pushRepo = StarterKit.sl<PushNotificationsRepository>();

// Initialize
await pushRepo.initialize(AppEnv.oneSignalAppId);

// Set user ID (after auth)
await pushRepo.setUserId('user_123');

// Set email
await pushRepo.setEmail('user@example.com');

// Send tags for targeting
await pushRepo.sendTags({
  'user_type': 'premium',
  'engagement_level': UserTargetingManager.instance.getUserSegment(),
});

// Enable/disable
await pushRepo.enable();
await pushRepo.disable();
```

## Interaction Map

- **Auth** → Set user ID after sign-in
- **IAP** → Tag users as `premium` or `free`
- **Tracking** → Send engagement segment as tags
- **Settings** → Toggle notifications on/off

## Checklist

- [ ] OneSignal app ID in env config
- [ ] `initialize()` called in main.dart or after auth
- [ ] User ID set after authentication
- [ ] User segment tags sent
- [ ] APNs (iOS) and FCM (Android) configured
- [ ] Settings toggle wired to enable/disable
