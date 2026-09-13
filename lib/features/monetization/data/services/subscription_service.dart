import 'package:genrevibes_iap/genrevibes_iap.dart';
import '../../domain/app_purchase_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:storysaver/container_injector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager extends ChangeNotifier {
  // Singleton pattern
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  int _generation = 0;
  bool _isPremium = false;
  EntitlementSnapshot? snapshot;

  void updateEntitlements(EntitlementSnapshot value) {
    snapshot = value;
    updatePremiumAccess(AppPurchasePolicy.isPremium(value));
  }

  bool _isInitialized = false;
  bool _preferencesLoaded = false;
  bool _hasReachedFirstStatus = false;
  bool _hasStatusFolderAccess = false;
  bool _onboardingActive = false;
  bool get hasStatusFolderAccess => _hasStatusFolderAccess;

  void setOnboardingActive(bool active) {
    if (_onboardingActive == active) return;
    _onboardingActive = active;
    notifyListeners();
  }

  Future<void> markStatusFolderGranted() async {
    if (_hasStatusFolderAccess) return;
    _hasStatusFolderAccess = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('status_folder_granted_once', true);
  }

  bool get hasReachedFirstStatus => _hasReachedFirstStatus;

  /// Analytics milestone, independent of ad eligibility.
  Future<void> markFirstStatusReached() async {
    if (_hasReachedFirstStatus) return;
    _hasReachedFirstStatus = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('status_connection_first_display', true);
  }

  /// Unknown subscription/override state must never request inventory.
  bool get adsAllowed =>
      _preferencesLoaded &&
      _isInitialized &&
      !isPremium &&
      (_hasStatusFolderAccess || _onboardingActive);

  void updatePremiumAccess(bool premium) {
    _isPremium = premium;
    _isInitialized = true;
    _lastChecked = DateTime.now();
    notifyListeners();
  }

  void refreshAccessPolicy() => notifyListeners();
  DateTime? _lastChecked;

  // Debug override - simulates a premium user. Honoured only while this device
  // has developer access: every development build, a listed developer device,
  // or the passcode this session. The switch stays saved, so a store build
  // whose passcode session ended is not left premium.
  bool debugOverridePremium = false;

  bool get _hasDeveloperAccess =>
      sl.isRegistered<DeveloperAccessController>() &&
      sl<DeveloperAccessController>().allows(DeveloperAction.premiumSimulation);

  /// Returns true if user is premium OR if the debug override applies
  bool get isPremium {
    if (debugOverridePremium && _hasDeveloperAccess) {
      print(
        'SubscriptionManager: Debug override active - granting premium access',
      );
      return true;
    }
    return _isPremium;
  }

  bool get isInitialized => _isInitialized;

  static const String _debugPremiumKey = "debug_premium_override";

  Future<void> loadPreferences() async {
    final generation = _generation;
    // Load once so a concurrent initialize cannot overwrite a just-toggled
    // in-memory premium override with an older preference value.
    if (!_preferencesLoaded) {
      final prefs = await SharedPreferences.getInstance();
      if (generation != _generation) return;
      if (!_preferencesLoaded) {
        debugOverridePremium = prefs.getBool(_debugPremiumKey) ?? false;
        _hasReachedFirstStatus =
            _hasReachedFirstStatus ||
            (prefs.getBool('status_connection_first_display') ?? false);
        _hasStatusFolderAccess =
            _hasStatusFolderAccess ||
            _hasReachedFirstStatus ||
            (prefs.getBool('status_folder_granted_once') ?? false);
        _preferencesLoaded = true;
        notifyListeners();
      }
    }
  }

  /// Initialize and check subscription status.
  Future<void> initialize() async {
    await loadPreferences();
    if (_isInitialized && _lastChecked != null) {
      // If checked within last 5 minutes, use cached value
      final difference = DateTime.now().difference(_lastChecked!);
      if (difference.inMinutes < 5) {
        print(
          'SubscriptionManager: Using cached subscription status: $_isPremium',
        );
        return;
      }
    }

    await checkSubscriptionStatus();
  }

  /// Toggle debug premium override
  Future<void> toggleDebugPremium(bool value) async {
    if (value && !_hasDeveloperAccess) return;
    debugOverridePremium = value;
    _preferencesLoaded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPremiumKey, value);
    notifyListeners();
    print('SubscriptionManager: Debug premium override set to $value');
  }

  /// Check current subscription status from RevenueCat
  Future<void> checkSubscriptionStatus() async {
    final generation = _generation;
    try {
      print('SubscriptionManager: Checking subscription status...');
      final result = await sl<IapProvider>().getEntitlements().timeout(
        const Duration(seconds: 15),
      );
      if (generation != _generation) return;
      result.fold(
        onSuccess: (snapshot) => updateEntitlements(snapshot),
        onFailure: (_) {
          // Keep known premium access, but do not authorize requests on error.
          _isInitialized = false;
          _lastChecked = null;
          notifyListeners();
        },
      );

      print(
        'SubscriptionManager: Subscription status updated - isPremium: $_isPremium',
      );
    } catch (e) {
      if (generation != _generation) return;
      print('SubscriptionManager: Error checking subscription status: $e');
      // A failed lookup is not proof of free access.
      _isInitialized = false;
      _lastChecked = null;
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
    _generation++;
    snapshot = null;
    _isPremium = false;
    _onboardingActive = false;
    _isInitialized = false;
    _lastChecked = null;
    notifyListeners();
  }
}
