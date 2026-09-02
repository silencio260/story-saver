import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/home_page.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Monetization/SubscriptionManager.dart';
import 'package:storysaver/Services/AutoSaveService.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

void switchToBusinessMode(BuildContext context) {
  final provider = Provider.of<GetStatusProvider>(context, listen: false);

  provider.setIsBusinessMode(!provider.isBusinessMode);
  provider.clearAllStatus();
  // Provider.of<GetStatusProvider>(context, listen: false).setIsBusinessMode();

  if (provider.isBusinessMode == true) {
    AnalyticsService.logSwitchToBusinessMode();
  } else {
    AnalyticsService.logSwitchToNormalMode();
  }

  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (BuildContext ctx) => const HomePage(),
    ),
  );
}

bool checkIsBusinessMode(BuildContext context) {
  return Provider.of<GetStatusProvider>(context, listen: false).isBusinessMode;

  // print("_checkIsBusinessMode ${Provider.of<GetStatusProvider>(context, listen: false).isBusinessMode}");

  // final InAppReview inAppReview = InAppReview.instance;
  // final result_ = await inAppReview.isAvailable();
  // print('Is inAppReview.requestReview() -> ${result_}');
}

/// Checks if user has premium access and enforces premium-only features
/// - If in Business Mode without premium: switches to Personal Mode
/// - If Auto Save is enabled without premium: disables Auto Save
Future<void> checkAndEnforceBusinessModeAccess(BuildContext context) async {
  final provider = Provider.of<GetStatusProvider>(context, listen: false);
  final isPremium = SubscriptionManager().isPremium;

  // If user is in Business Mode but doesn't have premium access
  if (provider.isBusinessMode && !isPremium) {
    print(
        "PremiumEnforcement: User lost premium access, switching to Personal Mode");
    provider.setIsBusinessMode(false);
    provider.clearAllStatus();
    AnalyticsService.logSwitchToNormalMode();
  }

  // If Auto Save is enabled but user doesn't have premium access
  final prefs = await SharedPreferences.getInstance();
  final isAutoSaveEnabled =
      prefs.getBool(AppConstants().IS_AUTO_SAVE_ENABLED) ?? false;

  if (isAutoSaveEnabled && !isPremium) {
    print("PremiumEnforcement: User lost premium access, disabling Auto Save");
    await prefs.setBool(AppConstants().IS_AUTO_SAVE_ENABLED, false);
    await AutoSaveService.cancelAllTasks();
  }
}
