// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:in_app_review/in_app_review.dart';
//
//
// class AppRatingService {
//   static void init() async{
//     final InAppReview inAppReview = InAppReview.instance;
//
//     if (await inAppReview.isAvailable()) {
//     inAppReview.requestReview();
//     }
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class AdvancedAppRatingService {
  static const String _installDateKey = "app_install_date";
  static const String _appOpensKey = "app_opens_count";
  static const String _lastReviewKey = "last_review_date";
  static const String _areadyReviewed = 'already_reviewd_app';

  static int _minAppOpens = 5; // Minimum app opens before showing review
  static int _minDaysAfterInstall = 7; // Minimum days after install
  static int _minDaysBetweenReviews = 14; // Minimum days between reviews

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

  static Future<bool> _meetsConditions() async {
    final prefs = await SharedPreferences.getInstance();

    int installDate = prefs.getInt(_installDateKey) ?? 0;
    int appOpens = prefs.getInt(_appOpensKey) ?? 0;
    int lastReviewDate = prefs.getInt(_lastReviewKey) ?? 0;
    bool alredyReviewed = prefs.getBool('has_shown_review') ?? false;

    int currentTime = DateTime.now().millisecondsSinceEpoch;

    bool meetsInstallDate = currentTime - installDate >= _minDaysAfterInstall * 24 * 60 * 60 * 1000;
    bool meetsAppOpens = appOpens >= _minAppOpens;
    bool meetsReviewInterval = currentTime - lastReviewDate >= _minDaysBetweenReviews * 24 * 60 * 60 * 1000;

    return meetsInstallDate && meetsAppOpens && meetsReviewInterval && !alredyReviewed;
  }

  static Future<void> showReviewDialogIfEligible(BuildContext context) async {
    if (await _meetsConditions()) {

      AdvancedAppRatingService().askForFeedbackOrReview(context);
    }
  }

  static Future<void> _recordReview() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_lastReviewKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _setAreadyReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_areadyReviewed, true);
  }

  // Developer customization methods
  static void setMinAppOpens(int count) {
    _minAppOpens = count;
  }

  static void setMinDaysAfterInstall(int days) {
    _minDaysAfterInstall = days;
  }

  static void setMinDaysBetweenReviews(int days) {
    _minDaysBetweenReviews = days;
  }

   Future<void> askForFeedbackOrReview(BuildContext context) async {
    bool isHappy = await _showCustomPromptForFeedback(context); // Ask if they're happy

    if (isHappy) {
      // await AdvancedAppRatingService.showReviewDialogIfEligible(); // Prompt happy users
      final InAppReview inAppReview = InAppReview.instance;

      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await _recordReview();
        await _setAreadyReviewed();
      }
    }
  }

  static Future<void> showAskForReviewDialogOnClick(BuildContext context) async {
    AdvancedAppRatingService().askForFeedbackOrReview(context);
  }

  Future<bool> _showCustomPromptForFeedback(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enjoying the app?'),
          content: Text('Would you like to let us know how we’re doing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not Really'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes!'),
            ),
          ],
        );
      },
    );
  }

  // void _redirectToFeedbackForm() {
  //   final feedbackUrl = 'https://yourapp.com/feedback'; // Replace with your form URL
  //   launch(feedbackUrl);
  // }
}


