---
name: iap
description: Subscription and one-time purchase management via RevenueCat with Clean Architecture
---

# In-App Purchases (IAP)

## Overview

IAP handles subscriptions and one-time purchases using RevenueCat. The starter kit provides a complete BLoC-based implementation. The app feature layer wraps the starter kit's IAP with app-specific logic.

## Prerequisites

- Starter kit integrated (see `starter-kit/SKILL.md`)
- RevenueCat account + API key configured
- `revenue_cat_api_key_android` and `revenue_cat_api_key_ios` in env config (see `skills/env-config/SKILL.md`)
- Entitlements, Offerings, and Products configured in RevenueCat dashboard
- App Store / Play Store products configured

## Architecture

The starter kit handles the IAP infrastructure:

```
starter_kit/lib/features/iap/
├── data/datasources/   # RevenueCat data source
├── domain/repositories/ # IAP repository interface
└── presentation/bloc/   # IapBloc with events/states
```

App-level wrapper (if needed):

```
features/iap/
├── iap_injector.dart
├── presentation/
│   ├── screens/
│   │   └── subscription_screen.dart
│   └── widgets/
│       └── product_card.dart
```

## Implementation

### Access via Starter Kit

```dart
// Initialize (automatic with StarterKit)
StarterKit.iapBloc.add(const IapInitialize());

// Purchase a product
StarterKit.iapBloc.add(IapPurchaseProduct(productId: 'premium_monthly'));

// Restore purchases
StarterKit.iapBloc.add(const IapRestorePurchases());

// Listen to state
BlocListener<IapBloc, IapState>(
  listener: (context, state) {
    if (state is IapInitialized) {
      final isSubscribed = state.subscriptionStatus.isActive;
      final products = state.products;
    }
  },
)
```

### Check Subscription Status

```dart
final iapState = StarterKit.iapBloc.state;
if (iapState is IapInitialized) {
  return iapState.subscriptionStatus.isActive;
}
return false;
```

## ProGuard / R8 (Android)

To prevent RevenueCat classes from being stripped during release builds, keep rules are required. While the `starter_kit` package provides these automatically via `consumerProguardFiles`, it is **highly recommended** to also include them in your app's `android/app/proguard-rules.pro` for redundancy and visibility.

1. Ensure `minifyEnabled true` is set in your app's `build.gradle`.
2. Add the following to your app's `proguard-rules.pro`:

```proguard
# RevenueCat Proguard Rules
-keep class com.revenuecat.purchases.** { *; }
-keep class com.revenuecat.purchases.ui.** { *; }
-keep class com.revenuecat.** { *; }

# Prevent obfuscation
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
```

## Interaction Map

- **Paywall** → Shows products, triggers purchase
- **Content Locking** → Checks subscription status
- **Ads** → Disable ads for subscribers
- **Analytics** → Log purchase events, revenue
- **Settings** → Restore purchases, manage subscription
- **Tracking** → Target offers by user segment

## Special Features

### RevenueCat Linking
- **Setup**: `StarterKit` initializes RevenueCat using platform-specific API keys from `EnvConfig`.
- **User Mapping**: The `appUserId` is automatically tied to the `Firebase Auth` UID.

### Entitlement Checks
- **Source of Truth**: Always check `subscriptionStatus.isActive` for the most reliable entitlement check.
- **Cache**: Subscritpion status is cached locally by RevenueCat, allowing for offline entitlement verification.

### Triggering the Paywall
- **Automatic**: Use the `PaywallGate` widget from `starter_kit` to wrap features that require premium. It handles the subscription check and shows the paywall if needed.
- **Manual**:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const PaywallScreen()),
  );
  ```

### Manage Subscription
- **Implementation**: In `SettingsPanelScreen`, the subscription section dynamically switches between "Go Pro" and "Manage Subscription" based on `StarterKit.subscriptionManager.isPremium`.
- **Functionality**: 
  - Displays "Premium Active" status.
  - Provides a "Manage" button that opens the respective store's subscription page (Google Play or Apple App Store).
- **Debug Support**: Fully integrated with "Debug Premium" for testing the premium UI state.

## Checklist

- [ ] RevenueCat API key in env config
- [ ] Products configured in App Store / Play Store
- [ ] Products configured in RevenueCat dashboard
- [ ] `IapBloc` provided in widget tree
- [ ] Subscription status checked for content locking
- [ ] Purchase and restore flows tested
- [ ] Analytics events logged for purchases
