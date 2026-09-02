import 'package:flutter/widgets.dart';
import 'package:storysaver/Analytics/RetentionTracker.dart';
import 'package:storysaver/Services/analytics_service.dart';

/// User engagement levels
enum UserEngagementLevel {
  FIRST_TIME, // First session ever
  LOW, // <3 days active or <5 total opens
  MEDIUM, // 3-6 days active or 5-15 opens
  HIGH, // 7-20 days active or 15-50 opens
  POWER_USER, // 20+ days active or 50+ opens
}

/// Targeting and segmentation logic using RetentionTracker data
///
/// This class contains NO data storage - it only queries RetentionTracker
///
/// Usage:
/// ```dart
/// await UserTargetingManager.startTracking();
/// ```
class UserTargetingManager with WidgetsBindingObserver {
  // Singleton pattern
  static final UserTargetingManager _instance =
      UserTargetingManager._internal();
  factory UserTargetingManager() => _instance;
  UserTargetingManager._internal();

  final RetentionTracker _tracker = RetentionTracker();

  /// Initialize retention tracking and log all relevant events.
  /// Call this once in your main() or home page initState().
  ///
  /// This handles:
  /// 1. App Open tracking (Cold start)
  /// 2. Session tracking (Background -> Foreground)
  /// 3. User Segmentation logging
  /// 4. Retention Analytics logging
  static Future<void> startTracking() async {
    print('UserTargetingManager: Starting retention tracking...');

    // 1. Track App Open (logs retention_app_opened)
    await RetentionTracker().trackAppOpen();

    // 2. Log User Segment (logs user_segment_update, user_is_loyal, etc.)
    await _instance.logUserSegment();

    // 3. Register lifecycle observer for session tracking
    WidgetsBinding.instance.addObserver(_instance);

    print('UserTargetingManager: Tracking complete.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('UserTargetingManager: App resumed - tracking session');
      _tracker.trackSession();
    }
  }

  // ========== USER SEGMENTATION ==========

  /// User is in their very first session
  bool isFirstTimeUser() {
    return _tracker.getTotalAppOpens() == 1;
  }

  /// User is less than 7 days old
  bool isNewUser() {
    return _tracker.getDaysSinceInstall() < 7;
  }

  /// User came back after their first day
  bool isReturningUser() {
    return _tracker.getTotalAppOpens() > 1;
  }

  /// User has been active for 7+ days
  bool isLoyalUser() {
    final activeDays = _tracker.getActiveDays().length;
    return activeDays >= 7;
  }

  /// User with very high engagement (20+ active days or 50+ opens)
  bool isPowerUser() {
    final activeDays = _tracker.getActiveDays().length;
    final totalOpens = _tracker.getTotalAppOpens();
    return activeDays >= 20 || totalOpens >= 50;
  }

  /// User hasn't opened app in 3+ days
  bool isAtRiskOfChurn() {
    final daysSinceLastOpen = _tracker.getDaysSinceLastOpen();
    return daysSinceLastOpen >= 3 && daysSinceLastOpen < 7;
  }

  /// User hasn't opened app in 7+ days
  bool isChurned() {
    return _tracker.getDaysSinceLastOpen() >= 7;
  }

  /// User opens app multiple times per day
  bool isFrequentUser() {
    return _tracker.getSessionCountToday() >= 3;
  }

  /// Get overall engagement level
  UserEngagementLevel getEngagementLevel() {
    if (isFirstTimeUser()) return UserEngagementLevel.FIRST_TIME;
    if (isPowerUser()) return UserEngagementLevel.POWER_USER;

    final activeDays = _tracker.getActiveDays().length;
    final totalOpens = _tracker.getTotalAppOpens();

    if (activeDays >= 7 || totalOpens >= 15) return UserEngagementLevel.HIGH;
    if (activeDays >= 3 || totalOpens >= 5) return UserEngagementLevel.MEDIUM;
    return UserEngagementLevel.LOW;
  }

  // ========== OFFER TIMING ==========

  /// Show welcome offer to brand new users (first session)
  bool shouldShowWelcomeOffer() {
    return isFirstTimeUser();
  }

  /// Show onboarding tips for days 1-3
  bool shouldShowOnboardingTips() {
    final days = _tracker.getDaysSinceInstall();
    return days >= 0 && days <= 3;
  }

  /// Show retention offer on day 3 if user hasn't returned much
  bool shouldShowRetentionOffer() {
    final daysSinceInstall = _tracker.getDaysSinceInstall();
    final activeDays = _tracker.getActiveDays().length;

    // Day 3 and only 1-2 active days
    return daysSinceInstall == 3 && activeDays <= 2;
  }

  /// Show loyalty reward on day 7 for active users
  bool shouldShowLoyaltyReward() {
    final daysSinceInstall = _tracker.getDaysSinceInstall();
    final d7Rate = _tracker.getD7RetentionRate();

    // Day 7 and >50% D7 retention
    return daysSinceInstall == 7 && d7Rate >= 50.0;
  }

  /// Show re-engagement offer for at-risk users
  bool shouldShowReEngagementOffer() {
    return isAtRiskOfChurn();
  }

  /// Show winback offer when churned user returns
  bool shouldShowWinbackOffer() {
    final daysSinceLastOpen = _tracker.getDaysSinceLastOpen();
    final wasChurned =
        daysSinceLastOpen == 0 && _tracker.getDaysSinceInstall() >= 7;

    // Just opened today after being gone 7+ days
    return wasChurned;
  }

  // ========== FEATURE TARGETING ==========

  /// Show advanced features to power users
  bool shouldShowAdvancedFeatures() {
    return isPowerUser() || getEngagementLevel() == UserEngagementLevel.HIGH;
  }

  /// Show premium upsell to engaged users
  bool shouldShowPremiumUpsell() {
    final level = getEngagementLevel();
    return level == UserEngagementLevel.HIGH ||
        level == UserEngagementLevel.POWER_USER;
  }

  /// Prompt for app rating (D3-D7, active)
  bool shouldShowRatingPrompt() {
    final days = _tracker.getDaysSinceInstall();
    final activeDays = _tracker.getActiveDays().length;

    // Between days 3-7 and at least 3 active days
    return days >= 3 && days <= 7 && activeDays >= 3;
  }

  /// Request notification permissions (D2, engaged)
  bool shouldRequestNotifications() {
    final days = _tracker.getDaysSinceInstall();
    final totalOpens = _tracker.getTotalAppOpens();

    // Day 2 and at least 3 opens
    return days == 2 && totalOpens >= 3;
  }

  /// Show tutorial/help based on low engagement
  bool shouldShowHelpTutorial() {
    final level = getEngagementLevel();
    return level == UserEngagementLevel.LOW;
  }

  // ========== ANALYTICS HELPERS ==========

  /// Get user segment as string
  String getUserSegment() {
    if (isPowerUser()) return 'power_user';
    if (isLoyalUser()) return 'loyal';
    if (isChurned()) return 'churned';
    if (isAtRiskOfChurn()) return 'at_risk';
    if (isReturningUser()) return 'returning';
    if (isFirstTimeUser()) return 'first_time';
    return 'new';
  }

  /// Calculate engagement score (0-100)
  int getEngagementScore() {
    final activeDays = _tracker.getActiveDays().length;
    final totalOpens = _tracker.getTotalAppOpens();
    final daysSinceInstall = _tracker.getDaysSinceInstall();
    final d7Rate = _tracker.getD7RetentionRate();

    // Scoring components
    int score = 0;

    // Active days (max 40 points)
    score += (activeDays * 2).clamp(0, 40);

    // Total opens (max 30 points)
    score += (totalOpens ~/ 2).clamp(0, 30);

    // D7 retention rate (max 20 points)
    score += (d7Rate / 5).toInt().clamp(0, 20);

    // Recency bonus (max 10 points)
    final daysSinceLastOpen = _tracker.getDaysSinceLastOpen();
    if (daysSinceLastOpen == 0)
      score += 10;
    else if (daysSinceLastOpen == 1) score += 5;

    return score.clamp(0, 100);
  }

  /// Get complete user profile for analytics
  Map<String, dynamic> getUserProfile() {
    return {
      'segment': getUserSegment(),
      'engagement_level': getEngagementLevel().toString().split('.').last,
      'engagement_score': getEngagementScore(),
      'is_first_time': isFirstTimeUser(),
      'is_new': isNewUser(),
      'is_returning': isReturningUser(),
      'is_loyal': isLoyalUser(),
      'is_power_user': isPowerUser(),
      'is_at_risk': isAtRiskOfChurn(),
      'is_churned': isChurned(),
      'is_frequent': isFrequentUser(),
      'days_since_install': _tracker.getDaysSinceInstall(),
      'days_since_last_open': _tracker.getDaysSinceLastOpen(),
      'total_opens': _tracker.getTotalAppOpens(),
      'active_days_count': _tracker.getActiveDays().length,
    };
  }

  /// Get offer recommendations
  List<String> getRecommendedOffers() {
    final List<String> offers = [];

    if (shouldShowWelcomeOffer()) offers.add('welcome_offer');
    if (shouldShowOnboardingTips()) offers.add('onboarding_tips');
    if (shouldShowRetentionOffer()) offers.add('retention_offer');
    if (shouldShowLoyaltyReward()) offers.add('loyalty_reward');
    if (shouldShowReEngagementOffer()) offers.add('reengagement_offer');
    if (shouldShowWinbackOffer()) offers.add('winback_offer');
    if (shouldShowPremiumUpsell()) offers.add('premium_upsell');
    if (shouldShowRatingPrompt()) offers.add('rating_prompt');
    if (shouldRequestNotifications()) offers.add('notification_request');
    if (shouldShowHelpTutorial()) offers.add('help_tutorial');

    // Log recommendations if any
    if (offers.isNotEmpty) {
      _logTargetingAnalytics('offers_recommended', {
        'recommended_offers': offers.join(','),
        'offer_count': offers.length,
      });
    }

    return offers;
  }

  /// Helper to log targeting analytics
  Future<void> _logTargetingAnalytics(
      String eventName, Map<String, dynamic> extraParams) async {
    final params = getUserProfile();
    params.addAll(extraParams);

    await AnalyticsService.logTargetingEvent(eventName, params);
  }

  /// Log when a specific offer is shown
  Future<void> logOfferShown(String offerType) async {
    await _logTargetingAnalytics('offer_shown', {'offer_type': offerType});
  }

  /// Log when a user segment changes (call this periodically or on app open)
  Future<void> logUserSegment() async {
    final params = getUserProfile();
    await AnalyticsService.logUserSegmentEvent('user_segment_update', params);

    if (isLoyalUser())
      await AnalyticsService.logUserSegmentEvent('user_is_loyal', params);
    if (isAtRiskOfChurn())
      await AnalyticsService.logUserSegmentEvent('user_at_risk', params);
    if (isChurned())
      await AnalyticsService.logUserSegmentEvent('user_churned', params);
    if (isPowerUser())
      await AnalyticsService.logUserSegmentEvent('user_is_power_user', params);
  }

  // ========== DEBUG HELPERS ==========

  /// Print user profile for debugging
  void printUserProfile() {
    print('========== USER PROFILE ==========');
    final profile = getUserProfile();
    profile.forEach((key, value) {
      print('$key: $value');
    });
    print('Recommended Offers: ${getRecommendedOffers().join(', ')}');
    print('==================================');
  }
}
