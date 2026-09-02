import 'package:flutter/foundation.dart';

/// Manages ad suppression state to prevent ads during critical user flows
///
/// Use this to temporarily disable ads during modals, paywalls, or other
/// important UX flows where ads would be disruptive.
///
/// Example usage:
/// ```dart
/// // Suppress ads
/// AdSuppressionManager().suppressAds('paywall');
///
/// // Show paywall
/// await showPaywall();
///
/// // Re-enable ads
/// AdSuppressionManager().enableAds('paywall');
/// ```
class AdSuppressionManager extends ChangeNotifier {
  // Singleton pattern
  static final AdSuppressionManager _instance =
      AdSuppressionManager._internal();
  factory AdSuppressionManager() => _instance;
  AdSuppressionManager._internal();

  // Track suppression reasons - multiple features can suppress simultaneously
  final Set<String> _suppressionReasons = {};

  /// Returns true if ads are currently suppressed by any reason
  bool get areAdsSuppressed => _suppressionReasons.isNotEmpty;

  /// Returns list of active suppression reasons (for debugging)
  List<String> get activeSuppressionReasons => _suppressionReasons.toList();

  /// Suppress ads for a specific reason
  ///
  /// [reason] - A unique identifier for why ads are suppressed
  /// Examples: 'paywall', 'premium_modal', 'onboarding', 'critical_dialog'
  void suppressAds(String reason) {
    final wasEmpty = _suppressionReasons.isEmpty;
    _suppressionReasons.add(reason);

    if (wasEmpty) {
      // Only notify if transition from not suppressed to suppressed
      print('AdSuppressionManager: Ads suppressed by: $reason');
      notifyListeners();
    } else {
      print(
        'AdSuppressionManager: Additional suppression added: $reason (total: ${_suppressionReasons.length})',
      );
    }
  }

  /// Re-enable ads for a specific reason
  ///
  /// Ads will only resume if all suppression reasons have been cleared
  void enableAds(String reason) {
    final removed = _suppressionReasons.remove(reason);

    if (removed) {
      print('AdSuppressionManager: Suppression removed: $reason');
      if (_suppressionReasons.isEmpty) {
        // Only notify if all suppressions cleared
        print(
          'AdSuppressionManager: All suppressions cleared - ads re-enabled',
        );
        notifyListeners();
      } else {
        print(
          'AdSuppressionManager: Still suppressed by: ${_suppressionReasons.join(', ')}',
        );
      }
    } else {
      print(
        'AdSuppressionManager: Warning - tried to remove non-existent reason: $reason',
      );
    }
  }

  /// Temporarily suppress ads while executing an async function
  ///
  /// Automatically re-enables ads after function completes (even if it throws)
  ///
  /// Example:
  /// ```dart
  /// await AdSuppressionManager().withAdsSuppressed(
  ///   reason: 'paywall',
  ///   action: () async {
  ///     await RevenueCatService().PresentRevenueCatPayWallIfNeeded();
  ///   },
  /// );
  /// ```
  Future<T> withAdsSuppressed<T>({
    required String reason,
    required Future<T> Function() action,
  }) async {
    suppressAds(reason);
    try {
      return await action();
    } finally {
      enableAds(reason);
    }
  }

  /// Clear all suppression reasons (use with caution)
  ///
  /// Typically used for error recovery or app state reset
  void clearAllSuppressions() {
    if (_suppressionReasons.isNotEmpty) {
      print(
        'AdSuppressionManager: Clearing all suppressions: ${_suppressionReasons.join(', ')}',
      );
      _suppressionReasons.clear();
      notifyListeners();
    }
  }

  /// Check if ads are suppressed for a specific reason
  bool isSuppressedBy(String reason) {
    return _suppressionReasons.contains(reason);
  }
}
