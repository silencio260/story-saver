import 'dart:io' show Platform;

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class RevenueCatService {
  CustomerInfo? _customerInfo;

  Future<void> ConfigureRevenueCatSDK() async {
    try {
      await Purchases.setDebugLogsEnabled(true);

      PurchasesConfiguration? configuration;

      const revenue_cat_api_key_android =
          const String.fromEnvironment("revenue_cat_api_key_android");
      print(
          'String.fromEnvironment("revenue_cat_api_key_android") ${revenue_cat_api_key_android}');
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

  Future<PaywallResult> PresentRevenueCatPayWallIfNeeded(
      {String entitlementId = 'Pro'}) async {
    try {
      print('in PresentRevenueCatPayWallIfNeeded');
      final paywallResult =
          await RevenueCatUI.presentPaywallIfNeeded(entitlementId);

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

        // await _analytics.logEvent(
        //   name: 'paywall_cancelled',
        //   parameters: {'entitlement_id': entitlementId},
        // );
      } else if (paywallResult == PaywallResult.restored) {
        print('User restored purchases');

        // await _analytics.logEvent(
        //   name: 'purchases_restored',
        //   parameters: {'entitlement_id': entitlementId},
        // );
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

      // await _analytics.logEvent(
      //   name: 'customer_center_viewed',
      // );
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
      // await _analytics.logPurchase(
      //   currency: currency,
      //   value: price,
      //   items: [
      //     AnalyticsEventItem(
      //       itemId: productId,
      //       itemName: entitlementId,
      //       price: price,
      //       quantity: 1,
      //     ),
      //   ],
      // );

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

  //------------------------------------------//
  //
  // // Track purchase made from paywall
  // Future<void> _trackPurchaseFromPaywall(
  //   CustomerInfo customerInfo,
  //   String entitlementId,
  // ) async {
  //   try {
  //     final entitlement = customerInfo.entitlements.all[entitlementId];
  //
  //     if (entitlement == null || !entitlement.isActive) {
  //       print('No active entitlement found for: $entitlementId');
  //       return;
  //     }
  //
  //     final productId = entitlement.productIdentifier;
  //     final price = entitlement.productPriceAmountMicros / 1000000;
  //     final currency = entitlement.currencyCode ?? 'USD';
  //     final verification = customerInfo.entitlements.verification;
  //
  //     print('Purchase verification: $verification');
  //
  //     // Only track verified or non-requested purchases
  //     if (verification == VerificationResult.verified ||
  //         verification == VerificationResult.notRequested) {
  //       // 1. Log to Firebase Analytics
  //       // await _analytics.logPurchase(
  //       //   currency: currency,
  //       //   value: price,
  //       //   items: [
  //       //     AnalyticsEventItem(
  //       //       itemId: productId,
  //       //       itemName: entitlementId,
  //       //       price: price,
  //       //       quantity: 1,
  //       //     ),
  //       //   ],
  //       // );
  //
  //       // 2. Save to Firestore
  //       // await _savePurchaseToFirestore(
  //       //   customerInfo: customerInfo,
  //       //   entitlement: entitlement,
  //       //   price: price,
  //       //   currency: currency,
  //       // );
  //     } else {
  //       print('Purchase verification failed: $verification');
  //     }
  //   } catch (e) {
  //     print('Error tracking purchase from paywall: $e');
  //   }
  // }

  // Check if user has active subscription
  Future<bool> hasActiveEntitlement(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementId];
      return entitlement?.isActive ?? false;
    } catch (e) {
      print('Error checking entitlement: $e');
      return false;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      print('Restoring purchases');

      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;

      // await _analytics.logEvent(
      //   name: 'purchases_restored',
      //   parameters: {
      //     'active_entitlements': customerInfo.entitlements.active.length,
      //   },
      // );

      print(
          'Purchases restored. Active entitlements: ${customerInfo.entitlements.active.length}');
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  // Get product price from offerings
  Future<Map<String, dynamic>> _getProductPrice(
      String productIdentifier) async {
    try {
      // Refresh offerings if not loaded
      final offerings = await Purchases.getOfferings();

      if (offerings == null) {
        return {'price': 0.0, 'currency': 'USD'};
      }

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
}

// print('REVENUE_CAT PURCHASE PRICE ${verification}');
