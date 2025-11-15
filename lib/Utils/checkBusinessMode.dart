import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Screens/home_page.dart';
import 'package:storysaver/Services/analytics_service.dart';

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
