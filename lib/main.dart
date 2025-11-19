import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Monetization/Ads/Admob/adConfig.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Provider/topNavProvider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/splash_screen.dart';
import 'package:storysaver/Services/Feedback_Helper/feedback_helper.dart';
import 'package:storysaver/Services/GDPR_Consent/gdprConsentMessage.dart';
import 'package:storysaver/Services/PostHogWrapper/posthog_wrapper.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Utils/checkDevelopmentMode.dart';
import 'package:storysaver/Utils/globalNavigationKey.dart';
import 'package:storysaver/Widget/MyRouteObserver.dart';

import 'Monetization/SubscriptionManager.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // PushNotification().initialize();

    RevenueCatService().ConfigureRevenueCatSDK();

    if (DevelopmentModeUtils.checkDevelopmentMode()) {
      // Enable premium testing
      SubscriptionManager().debugOverridePremium = true;
    }

    PostHogWrapper.init();

    MobileAds.instance.initialize();
    RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: ['5e2d630f-0073-4c73-b2b8-f05738eb5b6f']);
    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    print('ensureInitialized');

    String envvar = const String.fromEnvironment("founders_version");
    String e = AppConstants.SAVED_STORY_PATH;
    debugPrint(
        '#### Staging Env - $envvar - ${e} -  ${const String.fromEnvironment("firebase_api_key_android")} '
        '${const String.fromEnvironment("founders_version")}');

    //Init MediaStore
    await MediaStore.ensureInitialized();

    await handleGDPRConsent();

    AnalyticsService.init().then((onval) async {
      // final remoteConfigService = FirebaseRemoteConfigService();
      // remoteConfigService.initialize();
      await AdConfig.ensureInitialized();
    });

    FeedBackHelper.init();

    // await AdConfig.ensureInitialized();

    // await FirebaseRemoteConfigService().initialize();

    // await Firebase.initializeApp();

    // final remoteConfigService = FirebaseRemoteConfigService();
    // remoteConfigService.initialize();
  } catch (e) {
    print('Error in main function: $e');
  }

  runApp(MyApp());

  AnalyticsService.logAppOpen();

  AnalyticsService.logGotoSplashScreen();
}

class MyApp extends StatelessWidget {
  final MyRouteObserver routeObserver = MyRouteObserver();

  @override
  Widget build(BuildContext context) {
    return PostHogWidget(
        child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TopNavProvider()),
        ChangeNotifierProvider(create: (_) => GetStatusProvider()),
        ChangeNotifierProvider(create: (_) => GetSavedMediaProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        // ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // themeMode: themeProvider.themeMode,
        // theme: ThemeData.light(),
        // darkTheme: ThemeData.dark(),
        // theme: ThemeData(
        //   colorScheme: ColorScheme.light(
        //     primary: Colors.green, // Set the custom primary color
        //   ),
        // ),
        navigatorObservers: [routeObserver, PosthogObserver()],
        navigatorKey: myGlobalNavigatorKey,
        home: const SplashScreen(),
      ),
    ));
  }
}
