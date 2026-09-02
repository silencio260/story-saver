import 'package:flutter/widgets.dart';
import 'retention_tracker.dart';
import '../utils/analytics_names.dart';
import 'analytics_service.dart';

/// User engagement levels
enum UserEngagementLevel {
  firstTime, // First session ever
  low, // <3 days active or <5 total opens
  medium, // 3-6 days active or 5-15 opens
  high, // 7-20 days active or 15-50 opens
  powerUser, // 20+ days active or 50+ opens
}

extension UserEngagementLevelLabel on UserEngagementLevel {
  /// Stable analytics wire value. Kept SCREAMING_CASE for dashboard continuity
  /// after the enum identifiers were renamed to lowerCamelCase, so historical
  /// `engagement_level` data isn't split.
  String get analyticsLabel {
    switch (this) {
      case UserEngagementLevel.firstTime:
        return 'FIRST_TIME';
      case UserEngagementLevel.low:
        return 'LOW';
      case UserEngagementLevel.medium:
        return 'MEDIUM';
      case UserEngagementLevel.high:
        return 'HIGH';
      case UserEngagementLevel.powerUser:
        return 'POWER_USER';
    }
  }
}

/// Targeting and segmentation logic using RetentionTracker data
///
/// mirrors the functionality of the Status Saver template.
class UserTargetingManager with WidgetsBindingObserver {
  // Singleton pattern
  static final UserTargetingManager _instance =
      UserTargetingManager._internal();
  factory UserTargetingManager() => _instance;
  UserTargetingManager._internal();

  static UserTargetingManager get instance => _instance;

  final RetentionTracker _tracker = RetentionTracker.instance;
  AnalyticsService? _analytics;
  bool _observerRegistered = false;

  /// Initialize and start tracking, recording an app open in the process.
  ///
  /// Use when the caller owns the full retention lifecycle. If the app open
  /// has already been tracked elsewhere (e.g. `StarterKit.initialize`), use
  /// [startSegmentTracking] instead to avoid double-counting the open.
  static Future<void> startTracking(AnalyticsService analytics) async {
    _instance._analytics = analytics;

    // 1. Track App Open
    await _instance._tracker.trackAppOpen(analytics);

    // 2. Log User Segment
    await _instance.logUserSegment();

    // 3. Register lifecycle observer
    _instance._registerLifecycleObserver();
  }

  /// Begin segmentation + resume-driven session tracking WITHOUT recording an
  /// app open. Intended for callers that have already invoked
  /// [RetentionTracker.trackAppOpen] (such as `StarterKit.initialize`) and only
  /// need the user segment logged and the lifecycle observer attached.
  static Future<void> startSegmentTracking(AnalyticsService analytics) async {
    _instance._analytics = analytics;
    await _instance.logUserSegment();
    _instance._registerLifecycleObserver();
  }

  /// Attach the app-lifecycle observer once. Guarded so repeated
  /// initialization (e.g. hot restart) doesn't register duplicate observers.
  void _registerLifecycleObserver() {
    if (_observerRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _observerRegistered = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final analytics = _analytics;
    if (analytics != null && state == AppLifecycleState.resumed) {
      _tracker.trackSession(analytics);
    }
  }

  // ========== USER SEGMENTATION ==========

  bool isFirstTimeUser() => _tracker.getTotalAppOpens() == 1;
  bool isNewUser() => _tracker.getDaysSinceInstall() < 7;
  bool isReturningUser() => _tracker.getTotalAppOpens() > 1;
  bool isLoyalUser() => _tracker.getActiveDays().length >= 7;
  bool isPowerUser() {
    final activeDays = _tracker.getActiveDays().length;
    final totalOpens = _tracker.getTotalAppOpens();
    return activeDays >= 20 || totalOpens >= 50;
  }

  UserEngagementLevel getEngagementLevel() {
    if (isFirstTimeUser()) return UserEngagementLevel.firstTime;
    if (isPowerUser()) return UserEngagementLevel.powerUser;

    final activeDays = _tracker.getActiveDays().length;
    final totalOpens = _tracker.getTotalAppOpens();
    if (activeDays >= 7 || totalOpens >= 15) return UserEngagementLevel.high;
    if (activeDays >= 3 || totalOpens >= 5) return UserEngagementLevel.medium;
    return UserEngagementLevel.low;
  }

  String getUserSegment() {
    if (isPowerUser()) return 'power_user';
    if (isLoyalUser()) return 'loyal';
    if (isReturningUser()) return 'returning';
    if (isFirstTimeUser()) return 'first_time';
    return 'new';
  }

  Map<String, dynamic> getUserProfile() {
    return {
      'segment': getUserSegment(),
      'engagement_level': getEngagementLevel().analyticsLabel,
      'is_first_time': isFirstTimeUser() ? 1 : 0,
      'is_new': isNewUser() ? 1 : 0,
      'is_loyal': isLoyalUser() ? 1 : 0,
      'is_power_user': isPowerUser() ? 1 : 0,
      'days_since_install': _tracker.getDaysSinceInstall(),
      'total_opens': _tracker.getTotalAppOpens(),
    };
  }

  // ========== ANALYTICS HELPERS ==========

  Future<void> logUserSegment() async {
    final analytics = _analytics;
    if (analytics == null) return;

    final profile = getUserProfile();
    final names = AnalyticsNames.instance;

    await analytics.logUserSegmentEvent(names.segmentUpdate, profile);

    if (isLoyalUser()) {
      await analytics.logUserSegmentEvent(names.userIsLoyal, profile);
    }
    if (isPowerUser()) {
      await analytics.logUserSegmentEvent(names.userIsPowerUser, profile);
    }
  }

  Future<void> logOfferShown(String offerType) async {
    final analytics = _analytics;
    if (analytics == null) return;

    final params = getUserProfile();
    final names = AnalyticsNames.instance;
    params['offer_type'] = offerType;
    await analytics.logTargetingEvent(names.offerShown, params);
  }
}
