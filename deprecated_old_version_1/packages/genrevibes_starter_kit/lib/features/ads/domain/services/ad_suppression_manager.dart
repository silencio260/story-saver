import 'package:flutter/foundation.dart';

/// Manages ad suppression state to prevent ads during critical user flows
///
/// Use this to temporarily disable ads during modals, paywalls, or other
/// important UX flows where ads would be disruptive.
class AdSuppressionManager extends ChangeNotifier {
  // Singleton pattern
  static final AdSuppressionManager _instance =
      AdSuppressionManager._internal();
  factory AdSuppressionManager() => _instance;
  AdSuppressionManager._internal();

  static AdSuppressionManager get instance => _instance;

  // Track suppression reasons - multiple features can suppress simultaneously
  final Set<String> _suppressionReasons = {};

  // Track if an ad is currently being displayed to prevent overlaps
  bool _isAdShowing = false;

  /// Returns true if ads are currently suppressed by any reason or an ad is already showing
  bool get areAdsSuppressed => _suppressionReasons.isNotEmpty || _isAdShowing;

  /// Returns list of active suppression reasons (for debugging)
  List<String> get activeSuppressionReasons => _suppressionReasons.toList();

  /// Returns true if an ad is currently being displayed
  bool get isAdShowing => _isAdShowing;

  /// Set the ad showing state
  void setAdShowing(bool showing) {
    if (_isAdShowing != showing) {
      _isAdShowing = showing;
      notifyListeners();
      if (showing) {
        debugPrint(
          'AdSuppressionManager: Ad started showing - suppressing others',
        );
      } else {
        debugPrint(
          'AdSuppressionManager: Ad finished showing - others can proceed',
        );
      }
    }
  }

  /// Suppress ads for a specific reason
  ///
  /// [reason] - A unique identifier for why ads are suppressed
  void suppressAds(String reason) {
    final wasEmpty = _suppressionReasons.isEmpty;
    _suppressionReasons.add(reason);

    if (wasEmpty && !_isAdShowing) {
      debugPrint('AdSuppressionManager: Ads suppressed by: $reason');
      notifyListeners();
    } else {
      debugPrint('AdSuppressionManager: Additional suppression added: $reason');
    }
  }

  /// Re-enable ads for a specific reason
  void enableAds(String reason) {
    final removed = _suppressionReasons.remove(reason);

    if (removed) {
      debugPrint('AdSuppressionManager: Suppression removed: $reason');
      if (_suppressionReasons.isEmpty && !_isAdShowing) {
        debugPrint('AdSuppressionManager: All suppressions cleared');
        notifyListeners();
      }
    }
  }

  /// Temporarily suppress ads while executing an async function
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

  /// Clear all suppression reasons
  void clearAllSuppressions() {
    _isAdShowing = false;
    if (_suppressionReasons.isNotEmpty) {
      _suppressionReasons.clear();
      notifyListeners();
    }
  }
}
