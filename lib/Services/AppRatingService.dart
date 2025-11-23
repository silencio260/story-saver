import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Services/Feedback_Helper/feedback_helper.dart';
import 'package:storysaver/Widget/rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvancedAppRatingService {
  static const String _installDateKey = "app_install_date";
  static const String _appOpensKey = "app_opens_count";
  static const String _neverShowRatingKey = "never_show_rating";
  static const String _lastShownDateKey = "last_rating_shown_date";

  // Configuration variables
  static int _minAppOpens = 5; // Minimum app opens before showing review
  static int _minDaysAfterInstall = 3; // Minimum days after install
  static int _minDaysBetweenReviews = 7; // Minimum days between reviews
  static int _snoozeDays = 2; // Default snooze time

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Set install date if this is the first launch
    if (!prefs.containsKey(_installDateKey)) {
      prefs.setInt(_installDateKey, DateTime.now().millisecondsSinceEpoch);
    }

    // Increment app opens count
    int appOpens = prefs.getInt(_appOpensKey) ?? 0;
    prefs.setInt(_appOpensKey, appOpens + 1);
  }

  /// Configure the rating service aggressiveness and frequency
  static void setConfiguration({
    int? minAppOpens,
    int? minDaysAfterInstall,
    int? minDaysBetweenReviews,
    int? snoozeDays,
  }) {
    if (minAppOpens != null) _minAppOpens = minAppOpens;
    if (minDaysAfterInstall != null) _minDaysAfterInstall = minDaysAfterInstall;
    if (minDaysBetweenReviews != null)
      _minDaysBetweenReviews = minDaysBetweenReviews;
    if (snoozeDays != null) _snoozeDays = snoozeDays;
  }

  static Future<bool> _meetsConditions() async {
    final prefs = await SharedPreferences.getInstance();

    bool neverShow = prefs.getBool(_neverShowRatingKey) ?? false;
    if (neverShow) return false;

    int installDate = prefs.getInt(_installDateKey) ?? 0;
    int appOpens = prefs.getInt(_appOpensKey) ?? 0;
    int lastShownDate = prefs.getInt(_lastShownDateKey) ?? 0;

    int currentTime = DateTime.now().millisecondsSinceEpoch;

    bool meetsInstallDate =
        currentTime - installDate >= _minDaysAfterInstall * 24 * 60 * 60 * 1000;
    bool meetsAppOpens = appOpens >= _minAppOpens;
    bool meetsReviewInterval = currentTime - lastShownDate >=
        _minDaysBetweenReviews * 24 * 60 * 60 * 1000;

    return meetsInstallDate && meetsAppOpens && meetsReviewInterval;
  }

  /// Show the rating dialog if conditions are met.
  /// Set [force] to true to bypass all checks (for testing).
  static Future<void> showReviewDialogIfEligible(BuildContext context,
      {bool force = false}) async {
    if (force || await _meetsConditions()) {
      AdvancedAppRatingService().showRatingDialog(context);
    }
  }

  static Future<void> _setNeverShowRating() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_neverShowRatingKey, true);
  }

  static Future<void> _updateLastShownDate() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_lastShownDateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> showRatingDialog(BuildContext context) async {
    final RatingDialogResponse? response =
        await showDialog<RatingDialogResponse>(
      context: context,
      barrierDismissible: false, // Force user to choose an action
      builder: (context) => RatingDialog(),
    );

    if (response == null) return;

    switch (response.action) {
      case RatingAction.maybeLater:
        // Note: The snooze duration is handled by _meetsConditions checking _minDaysBetweenReviews
        // However, if we want a specific shorter snooze for "Maybe Later" vs "Already Rated" (if we allowed re-rating),
        // we might need separate logic. For now, "Maybe Later" just resets the timer.
        // If user wants specific snooze time different from normal interval:
        // We can temporarily override the last shown date or use a specific "snooze" key.
        // But based on request "snooze for 1 or 2 day", let's implement that specific logic.
        await _snoozeRating();
        break;
      case RatingAction.never:
        await _setNeverShowRating();
        break;
      case RatingAction.continue_:
        await _setNeverShowRating(); // Don't show again after they've rated/given feedback
        if (response.rating >= 4) {
          _launchPlayStoreOrInAppReview();
        } else {
          FeedBackHelper().showFeedBackDialog(context);
        }
        break;
    }
  }

  Future<void> _launchPlayStoreOrInAppReview() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      AdvancedAppRatingService.launchPlayStoreLink();
    }
  }

  static Future<void> _snoozeRating() async {
    final prefs = await SharedPreferences.getInstance();
    // Set last shown date such that it will be eligible again after _snoozeDays
    // We want: currentTime - lastShown >= snoozeDays
    // So: lastShown = currentTime - (minDaysBetweenReviews - snoozeDays)
    // Wait, simpler: just set lastShown to now, and ensure _meetsConditions uses a separate check or
    // we just rely on _minDaysBetweenReviews.
    // But user asked for specific snooze time (1-2 days) which might be different from standard interval (7 days).
    // Let's use a specific snooze mechanism.

    // Actually, the simplest way to respect "snooze days" is to set the last shown date
    // but we need _meetsConditions to know if it was a snooze or a regular interval.
    // For simplicity, let's just update the last shown date to now.
    // AND we need to make sure _meetsConditions uses _snoozeDays if it was a snooze?
    // Or better: Just set the last shown date to (Now - (Interval - Snooze)).
    // Example: Interval = 7 days, Snooze = 2 days.
    // We want it to show in 2 days.
    // _meetsConditions checks: Now - LastShown >= 7 days.
    // We want: (Now + 2days) - LastShown >= 7 days.
    // So LastShown = Now + 2days - 7days = Now - 5days.

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int effectiveLastShown = currentTime -
        ((_minDaysBetweenReviews - _snoozeDays) * 24 * 60 * 60 * 1000);

    prefs.setInt(_lastShownDateKey, effectiveLastShown);
  }

  static void launchPlayStoreLink() async {
    AnalyticsService.logGoToAppStorePage();
    final uri = Uri.parse(AppConstants().GOOGLE_PLAY_STORE_LINK);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch ${uri}';
    }
  }
}
