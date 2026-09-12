import 'dart:async';

import 'package:genrevibes_iap/genrevibes_iap.dart';

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

  /// The most recent entitlement snapshot, kept for the synchronous check the
  /// ad path relies on.
  static EntitlementSnapshot? _snapshot;

  static StreamSubscription<EntitlementSnapshot>? _subscription;

  /// Starts mirroring entitlement changes.
  ///
  /// The provider is already initialized; this only keeps [_snapshot] current
  /// so [isSubscriptionActive] can answer without awaiting.
  Future<void> ConfigureRevenueCatSDK() async {
    _subscription ??= _iap.entitlementChanges.listen((snapshot) {
      _snapshot = snapshot;
    });
    final result = await _iap.getEntitlements();
    result.fold(
      onSuccess: (snapshot) => _snapshot = snapshot,
      onFailure: (_) {},
    );
  }

  /// Shows the paywall when [entitlementId] is not already active.
  Future<PaywallOutcome> PresentRevenueCatPayWallIfNeeded({
    String entitlementId = 'Pro',
  }) async {
    await AnalyticsService.logViewPaywall();

    final result = await _iap.presentPaywall(
      requiredEntitlementId: entitlementId,
    );
    return result.fold(
      onSuccess: (purchase) {
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
            return PaywallOutcome.notPresented;
          case PurchaseStatus.notPurchased:
            AnalyticsService.track('paywall_not_presented');
            return PaywallOutcome.notPresented;
        }
      },
      onFailure: (error) {
        AnalyticsService.track('paywall_failed', {
          'error_code': error.code.name,
        });
        return PaywallOutcome.notPresented;
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
  }

  /// The latest entitlement snapshot, refreshed from the provider.
  Future<EntitlementSnapshot?> getCustomerInfo() async {
    final result = await _iap.getEntitlements();
    return result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        return snapshot;
      },
      onFailure: (_) => _snapshot,
    );
  }

  /// Restores previous purchases.
  Future<void> restorePurchases() async {
    await AnalyticsService.track('restore_purchases_requested');
    final result = await _iap.restorePurchases();
    result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        AnalyticsService.logCustomPurchasesRestored(entitlementId: 'Pro');
      },
      onFailure: (error) {
        AnalyticsService.track('restore_purchases_failed', {
          'error_code': error.code.name,
        });
      },
    );
  }

  Future<void> _trackNewPurchase() async {
    final snapshot = await getCustomerInfo();
    final entitlement = snapshot?.entitlements.firstOrNull;
    if (entitlement == null) return;
    await AnalyticsService.logCustomPurchase(
      currency: 'USD',
      price: 0,
      productId: entitlement.productId,
      entitlementId: entitlement.id,
    );
  }

  /// Whether any entitlement is active, fetched fresh.
  static Future<bool> checkSubscriptionStatus() async {
    final result = await sl<IapProvider>().getEntitlements();
    return result.fold(
      onSuccess: (snapshot) {
        _snapshot = snapshot;
        return snapshot.activeEntitlementIds.isNotEmpty;
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
    return _snapshot?.activeEntitlementIds.isNotEmpty ?? false;
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

  /// The paywall was not shown, or the attempt failed.
  notPresented,
}
