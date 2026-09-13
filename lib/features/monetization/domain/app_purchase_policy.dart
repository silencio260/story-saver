import 'package:genrevibes_iap/genrevibes_iap.dart';

/// Story Saver product choices. The rule implementation lives in the kit.
abstract final class AppPurchasePolicy {
  static const premiumEntitlement = String.fromEnvironment(
    'premium_entitlement_id',
    defaultValue: 'Pro',
  );
  static final access = EntitlementAccessPolicy([
    FeatureEntitlementRule(featureId: 'premium', anyOf: {premiumEntitlement}),
  ]);
  static bool isPremium(EntitlementSnapshot snapshot) =>
      access.isUnlocked('premium', snapshot);
}
