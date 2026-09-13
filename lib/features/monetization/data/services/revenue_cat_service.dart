import 'dart:async';

import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'subscription_service.dart';
import '../../domain/app_purchase_policy.dart';

import '../../../../container_injector.dart';
import '../../../analytics/data/services/analytics_service.dart';

/// Purchases, delivered through the starter kit's IAP provider.
///
/// This was a direct `purchases_flutter` and `purchases_ui_flutter` client. It
/// keeps its method names and signatures because the paywall, the ad
/// suppression controller, the subscription service and the settings screen
/// all call them; what changed is that RevenueCat types no longer cross this
/// boundary. `PaywallOutcome` replaces `PaywallResult`, so nothing outside the
/// adapter names a vendor enum.
///
/// The SDK is configured once by `bootstrapApp`. This class configures nothing.
class RevenueCatService {
  IapProvider get _iap => sl<IapProvider>();

  static EntitlementSnapshot? get _snapshot => SubscriptionManager().snapshot;
  static set _snapshot(EntitlementSnapshot? value) {
    if (value != null) SubscriptionManager().updateEntitlements(value);
  }

  /// Provider initialization belongs to bootstrap; this only refreshes access.
  Future<void> ConfigureRevenueCatSDK() async {
    await getCustomerInfo();
  }

  /// Shows the paywall when [entitlementId] is not already active.
  Future<PaywallOutcome> PresentRevenueCatPayWallIfNeeded({
    String entitlementId = AppPurchasePolicy.premiumEntitlement,
  }) async {
    await AnalyticsService.logViewPaywall();

    final result = await _iap.presentPaywall(
      requiredEntitlementId: entitlementId,
    );
    return result.fold(
      onSuccess: (purchase) {
        if (purchase.entitlements != null) _snapshot = purchase.entitlements;
        switch (purchase.status) {
          case PurchaseStatus.purchased:
            unawaited(_trackNewPurchase());
            return PaywallOutcome.purchased;
          case PurchaseStatus.restored:
            AnalyticsService.logCustomPurchasesRestored(
              entitlementId: entitlementId,
            );
            return PaywallOutcome.restored;
          case PurchaseStatus.cancelled:
            AnalyticsService.logCustomPaywallCancelled(
              entitlementId: entitlementId,
            );
            return PaywallOutcome.cancelled;
          case PurchaseStatus.pending:
            AnalyticsService.track('purchase_pending');
            return PaywallOutcome.pending;
          case PurchaseStatus.notPurchased:
            AnalyticsService.track('paywall_not_presented');
            return PaywallOutcome.notPresented;
        }
      },
      onFailure: (error) {
        AnalyticsService.track('paywall_failed', {
          'error_code': error.code.name,
        });
        throw error;
      },
    );
  }

  /// Shows RevenueCat's customer centre.
  Future<void> PresentRevenueCatCustomerCenter() async {
    final result = await _iap.presentCustomerCenter();
    await AnalyticsService.track(
      result.isSuccess
          ? 'custom_customer_center_viewed'
          : 'customer_center_failed',
    );
    result.fold(onSuccess: (_) {}, onFailure: (error) => throw error);
  }

  /// The latest entitlement snapshot, refreshed from the provider.
  Future<EntitlementSnapshot?> getCustomerInfo() async {
    final result = await _iap.getEntitlements().timeout(
      const Duration(seconds: 15),
    );
    return result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        return snapshot;
      },
      onFailure: (_) => _snapshot,
    );
  }

  /// Restores previous purchases.
  Future<KitResult<EntitlementSnapshot>> restorePurchases() async {
    await AnalyticsService.track('restore_purchases_requested');
    final result = await _iap.restorePurchases().timeout(
      const Duration(seconds: 30),
    );
    result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        AnalyticsService.logCustomPurchasesRestored(
          entitlementId: AppPurchasePolicy.premiumEntitlement,
        );
      },
      onFailure: (error) {
        AnalyticsService.track('restore_purchases_failed', {
          'error_code': error.code.name,
        });
      },
    );
    return result;
  }

  Future<void> _trackNewPurchase() async {
    final snapshot = await getCustomerInfo();
    if (snapshot == null) return;
    await AnalyticsService.track('purchase_completed', {
      'entitlement_id': AppPurchasePolicy.premiumEntitlement,
      'premium_active': AppPurchasePolicy.isPremium(snapshot),
    });
  }

  /// Whether any entitlement is active, fetched fresh.
  static Future<bool> checkSubscriptionStatus() async {
    final result = await sl<IapProvider>().getEntitlements();
    return result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        return AppPurchasePolicy.isPremium(snapshot);
      },
      onFailure: (_) => false,
    );
  }

  /// Whether any entitlement is active, from the last known snapshot.
  ///
  /// Returns false rather than throwing when nothing has been read yet. The
  /// previous implementation dereferenced a null customer info here, which
  /// crashed whenever the ad path ran before the first fetch completed.
  static bool isSubscriptionActive() {
    final snapshot = _snapshot;
    return snapshot != null && AppPurchasePolicy.isPremium(snapshot);
  }

  /// Whether one specific entitlement is active.
  static Future<bool> hasActiveEntitlement(String entitlementId) async {
    final result = await sl<IapProvider>().getEntitlements();
    return result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        return snapshot.activeEntitlementIds.contains(entitlementId);
      },
      onFailure: (_) => false,
    );
  }
}

/// The outcome of showing the paywall, without a vendor type.
enum PaywallOutcome {
  /// A purchase completed.
  purchased,

  /// Purchases were restored.
  restored,

  /// The user dismissed the paywall.
  cancelled,

  /// The store is still processing payment.
  pending,

  /// The paywall was not shown.
  notPresented,
}
