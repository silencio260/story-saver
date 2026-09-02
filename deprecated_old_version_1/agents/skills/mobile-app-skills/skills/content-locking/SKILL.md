---
name: content-locking
description: Lock features behind subscriptions, quotas, or ad views with gating logic
---

# Content Locking

## Overview

Content locking gates premium features behind subscriptions, usage quotas, or rewarded ad views. It uses a combination of IAP status, quota tracking, and env config flags (`founders_version`, `special_version_mode`) to determine access.

## Prerequisites

- IAP configured (see `skills/iap/SKILL.md`)
- Quota system (see `skills/quota-rate-limiting/SKILL.md`)
- Env config (see `skills/env-config/SKILL.md`)

## Implementation

### Gating Logic

```dart
class ContentGate {
  static bool canAccess(BuildContext context, {required String feature}) {
    // Founders always have access
    if (AppEnv.foundersVersion) return true;

    // Check subscription
    final iapState = StarterKit.iapBloc.state;
    if (iapState is IapInitialized && iapState.subscriptionStatus.isActive) {
      return true;
    }

    // Check feature-specific quota
    final quotaBloc = context.read<QuotaBloc>();
    return quotaBloc.hasRemainingQuota(feature);
  }

  static void handleLocked(BuildContext context, {required String feature}) {
    // Option 1: Show paywall
    Navigator.pushNamed(context, Routes.paywall);

    // Option 2: Offer rewarded ad
    // StarterKit.adsBloc.add(AdsShowRewarded());
  }
}
```

### Usage in Screens

```dart
onTap: () {
  if (ContentGate.canAccess(context, feature: 'image_generation')) {
    // Proceed
  } else {
    ContentGate.handleLocked(context, feature: 'image_generation');
  }
}
```

## Interaction Map

- **IAP / Paywall** → Primary unlock mechanism
- **Ads** → Rewarded ads as alternative unlock
- **Quota** → Usage-limited access for free users
- **Env Config** → `founders_version` bypasses all locks
- **Tracking** → Segment-aware gating (power users get more free usage)

## Checklist

- [ ] `ContentGate` utility created
- [ ] Subscription status checked via `IapBloc`
- [ ] Quota limits checked via `QuotaBloc`
- [ ] Founders version bypass implemented
- [ ] Paywall shown when locked
- [ ] Rewarded ad alternative available
