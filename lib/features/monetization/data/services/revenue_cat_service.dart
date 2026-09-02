import 'dart:io' show Platform;

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:storysaver/features/analytics/data/services/firebase_analytics_service.dart';

class RevenueCatService {
  static CustomerInfo? _customerInfo;

  Future<void> ConfigureRevenueCatSDK() async {
    try {
      await Purchases.setDebugLogsEnabled(true);

      PurchasesConfiguration? configuration;

      const revenue_cat_api_key_android = const String.fromEnvironment(
        "revenue_cat_api_key_android",
      );
      print(
        'String.fromEnvironment("revenue_cat_api_key_android") ${revenue_cat_api_key_android}',
      );
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(revenue_cat_api_key_android);
      } else if (Platform.isIOS) {
        // configuration = PurchasesConfiguration('<revenuecat_project_apple_api_key>');
      }

      print('revenue cat configuration ${configuration}');

      if (configuration != null) {
        await Purchases.configure(configuration);

        // PresentRevenueCatPayWallIfNeeded();

        // Set up purchase listener to track purchases automatically
        _setupPurchaseListener();

        // Get initial customer info
        _customerInfo = await Purchases.getCustomerInfo();
      }
    } catch (e) {
      print("Error initializing Purchases: $e");
    }
  }

  Future<PaywallResult> PresentRevenueCatPayWallIfNeeded({
    String entitlementId = 'Pro',
  }) async {
    try {
      print('in PresentRevenueCatPayWallIfNeeded');

      // Track analytics
      await AnalyticsService.logViewPaywall();

      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
      );

      print('Paywall Result: ${paywallResult}');

      // Track paywall result
      if (paywallResult == PaywallResult.purchased) {
        print('User made a purchase!');

        // Get updated customer info
        final customerInfo = await Purchases.getCustomerInfo();

        // Track the purchase
        await _trackNewPurchase(customerInfo);
      } else if (paywallResult == PaywallResult.cancelled) {
        print('User cancelled the purchase');

        // Paywall Cancelled Event
        AnalyticsService.logCustomPaywallCancelled(
          entitlementId: entitlementId,
        );
      } else if (paywallResult == PaywallResult.restored) {
        print('User restored purchases');

        // Purchases Restored Event (with entitlement_id)
        AnalyticsService.logCustomPurchasesRestored(
          entitlementId: entitlementId,
        );
      }

      return paywallResult;
    } catch (e) {
      print("Error PresentPayWallIfNeeded Purchases: $e");

      rethrow;
    }
  }

  Future<void> PresentRevenueCatCustomerCenter() async {
    try {
      print('in PresentRevenueCatPayWallIfNeeded');
      final paywallResult = await RevenueCatUI.presentCustomerCenter();

      // print('Paywall Result: $paywallResult');

      // Customer Center Viewed Event
      AnalyticsService.logCustomCustomerCenterViewed();
    } catch (e) {
      print("Error PresentPayWallIfNeeded Purchases: $e");
    }
  }

  void _setupPurchaseListener() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      print('Customer info updated');

      // Check if this is a new purchase by comparing with previous state
      final hadPurchase =
          _customerInfo?.entitlements.active.isNotEmpty ?? false;
      final hasPurchaseNow = customerInfo.entitlements.active.isNotEmpty;

      print('hadPurchase: $hadPurchase, hasPurchaseNow: $hasPurchaseNow');

      // If we didn't have active entitlements before but do now, it's a new purchase
      if (!hadPurchase && hasPurchaseNow) {
        print('New purchase detected!');
        await _trackNewPurchase(customerInfo);
      }

      _customerInfo = customerInfo;
    });
  }

  // Track new purchase to Firebase
  Future<void> _trackNewPurchase(CustomerInfo customerInfo) async {
    try {
      final activeEntitlements = customerInfo.entitlements.active;

      if (activeEntitlements.isEmpty) return;

      // Get the most recent entitlement
      final entitlement = activeEntitlements.values.first;

      final productId = entitlement.productIdentifier;
      final productDetails = await _getProductPrice(productId);
      final price = productDetails['price'] as double? ?? 0.0;
      final currency = productDetails['currency'] as String? ?? 'USD';
      final entitlementId = entitlement.identifier;

      print('Tracking purchase: $productId, $price $currency');

      // 1. Log to Firebase Analytics
      // Purchase Event
      AnalyticsService.logCustomPurchase(
        currency: currency,
        price: price,
        productId: productId,
        entitlementId: entitlementId,
      );

      print('Purchase tracked successfully');
    } catch (e) {
      print('Error tracking purchase: $e');
    }
  }

  // Get customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo;
    } catch (e) {
      print('Error getting customer info: $e');
      return null;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      print('Restoring purchases');

      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;

      // Purchases Restored Event (with entitlement_id)
      AnalyticsService.logCustomPurchasesRestored(
        entitlementId: customerInfo.entitlements.active.length.toString(),
      );

      print(
        'Purchases restored. Active entitlements: ${customerInfo.entitlements.active.length}',
      );
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  // Get product price from offerings
  Future<Map<String, dynamic>> _getProductPrice(
    String productIdentifier,
  ) async {
    try {
      // Refresh offerings if not loaded
      final offerings = await Purchases.getOfferings();

      // Search through all offerings for the product
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          if (package.storeProduct.identifier == productIdentifier) {
            return {
              'price': package.storeProduct.price,
              'currency': package.storeProduct.currencyCode,
              'priceString': package.storeProduct.priceString,
            };
          }
        }
      }

      // If not found in offerings, try getting it directly
      final products = await Purchases.getProducts([productIdentifier]);
      if (products.isNotEmpty) {
        final product = products.first;
        return {
          'price': product.price,
          'currency': product.currencyCode,
          'priceString': product.priceString,
        };
      }

      return {'price': 0.0, 'currency': 'USD'};
    } catch (e) {
      print('Error getting product price: $e');
      return {'price': 0.0, 'currency': 'USD'};
    }
  }

  //*****************************************
  // Subscription Status Check
  //*****************************************

  static Future<bool> checkSubscriptionStatus() async {
    try {
      print("Checking subscription status...");

      // Get the current customer info from RevenueCat
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // Check if there are any active entitlements
      final bool hasActiveSubscription =
          customerInfo.entitlements.active.isNotEmpty;

      print("Subscription active: $hasActiveSubscription");
      return hasActiveSubscription;
    } catch (e) {
      print("Error checking subscription status: $e");
      return false;
    }
  }

  // Check if subscription status has been loaded
  static bool isSubscriptionActive() {
    print('Customer Info ${_customerInfo}');
    // Check if there are any active entitlements
    final bool hasActiveSubscription =
        _customerInfo!.entitlements.active.isNotEmpty;

    return hasActiveSubscription;
  }

  // Alternative: Check for a specific entitlement
  static Future<bool> hasActiveEntitlement(String entitlementId) async {
    try {
      print("Checking entitlement: $entitlementId");

      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();

      // Check if the specific entitlement is active
      final bool isActive =
          customerInfo.entitlements.all[entitlementId]?.isActive ?? false;

      print("Entitlement $entitlementId active: $isActive");
      return isActive;
    } catch (e) {
      print("Error checking entitlement: $e");
      return false;
    }
  }

  // Future<bool> hasActiveEntitlement(String entitlementId) async {
  //   try {
  //     final customerInfo = await Purchases.getCustomerInfo();
  //     final entitlement = customerInfo.entitlements.all[entitlementId];
  //     return entitlement?.isActive ?? false;
  //   } catch (e) {
  //     print('Error checking entitlement: $e');
  //     return false;
  //   }
  // }
}

// print('REVENUE_CAT PURCHASE PRICE ${verification}');
