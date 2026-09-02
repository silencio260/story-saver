---
name: paywall
description: Subscription gate screen showing products and triggering IAP purchases
---

# Paywall

## Overview

The paywall is a full-screen subscription gate shown to free users when they try to access premium features. It displays available products from RevenueCat and triggers purchases via the IAP BLoC.

## Prerequisites

- IAP configured (see `skills/iap/SKILL.md`)
- Products set up in RevenueCat + App Store / Play Store

## Architecture

```
features/paywall/
├── presentation/
│   ├── screens/
│   │   └── paywall_screen.dart
│   └── widgets/
│       ├── product_card.dart
│       ├── feature_comparison.dart
│       └── pricing_toggle.dart
```

The paywall is primarily a **presentation-only** feature — it delegates to the starter kit `IapBloc` for business logic.

## Implementation

```dart
class PaywallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IapBloc, IapState>(
      builder: (context, state) {
        if (state is IapInitialized) {
          return Column(
            children: [
              // Feature highlights
              FeatureComparisonWidget(),
              // Product list
              ...state.products.map((product) => ProductCard(
                product: product,
                onPurchase: () {
                  StarterKit.iapBloc.add(IapPurchaseProduct(productId: product.id));
                },
              )),
              // Restore purchases
              TextButton(
                onPressed: () => StarterKit.iapBloc.add(const IapRestorePurchases()),
                child: Text('Restore Purchases'),
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## When to Show

```dart
// Check before accessing premium features
void accessPremiumFeature(BuildContext context) {
  final iapState = StarterKit.iapBloc.state;
  final isSubscribed = iapState is IapInitialized && iapState.subscriptionStatus.isActive;

  if (!isSubscribed) {
    Navigator.pushNamed(context, Routes.paywall);
    return;
  }
  // Proceed with feature
}
```

## Interaction Map

- **IAP** → Delegates purchases to `IapBloc`
- **Content Locking** → Triggers paywall when locked content accessed
- **Tracking** → Show different offers by user segment (`logOfferShown()`)
- **Analytics** → Log `paywall_shown`, `paywall_dismissed`, `purchase_initiated`
- **Ads** → Show rewarded ad as alternative to subscription

## Checklist

- [ ] Paywall screen created with product display
- [ ] Purchase buttons wired to `IapBloc`
- [ ] Restore purchases button included
- [ ] Feature comparison or benefits displayed
- [ ] Analytics events logged
- [ ] Targeted by user segment via `UserTargetingManager`
