import 'package:flutter/foundation.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Utils/checkDevelopmentMode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager extends ChangeNotifier {
  // Singleton pattern
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  bool _isPremium = false;
  bool _isInitialized = false;
  DateTime? _lastChecked;

  // Debug override - set to true to simulate premium user in development mode
  // This only works when DevelopmentModeUtils.checkDevelopmentMode() returns true
  bool debugOverridePremium = false;

  /// Returns true if user is premium OR if debug override is enabled in development mode
  bool get isPremium {
    if (debugOverridePremium && DevelopmentModeUtils.checkDevelopmentMode()) {
      print(
          'SubscriptionManager: Debug override active - granting premium access');
      return true;
    }
    return _isPremium;
  }

  bool get isInitialized => _isInitialized;

  static const String _debugPremiumKey = "debug_premium_override";

  /// Initialize and check subscription status
  Future<void> initialize() async {
    // Load debug override state
    final prefs = await SharedPreferences.getInstance();
    debugOverridePremium = prefs.getBool(_debugPremiumKey) ?? false;

    if (_isInitialized && _lastChecked != null) {
      // If checked within last 5 minutes, use cached value
      final difference = DateTime.now().difference(_lastChecked!);
      if (difference.inMinutes < 5) {
        print(
            'SubscriptionManager: Using cached subscription status: $_isPremium');
        return;
      }
    }

    await checkSubscriptionStatus();
  }

  /// Toggle debug premium override
  Future<void> toggleDebugPremium(bool value) async {
    debugOverridePremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPremiumKey, value);
    notifyListeners();
    print('SubscriptionManager: Debug premium override set to $value');
  }

  /// Check current subscription status from RevenueCat
  Future<void> checkSubscriptionStatus() async {
    try {
      print('SubscriptionManager: Checking subscription status...');
      final hasActiveSubscription =
          await RevenueCatService.checkSubscriptionStatus();

      _isPremium = hasActiveSubscription;
      _isInitialized = true;
      _lastChecked = DateTime.now();

      print(
          'SubscriptionManager: Subscription status updated - isPremium: $_isPremium');
      notifyListeners();
    } catch (e) {
      print('SubscriptionManager: Error checking subscription status: $e');
      // On error, assume not premium to show ads
      _isPremium = false;
      _isInitialized = true;
      _lastChecked = DateTime.now();
      notifyListeners();
    }
  }

  /// Force refresh subscription status (useful after purchase)
  Future<void> refreshSubscriptionStatus() async {
    _lastChecked = null;
    await checkSubscriptionStatus();
  }

  /// Reset subscription status (useful for logout)
  void reset() {
    _isPremium = false;
    _isInitialized = false;
    _lastChecked = null;
    notifyListeners();
  }
}
