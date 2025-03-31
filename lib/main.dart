import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Provider/bottom_nav_provider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/OnBoarding/onboardingPage.dart';
import 'package:storysaver/Screens/splash_screen.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Widget/MyRouteObserver.dart';
import 'package:storysaver/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('ensureInitialized');

  String envvar = const String.fromEnvironment("founders_version");
  String e = AppConstants.SAVED_STORY_PATH;
  debugPrint('#### Staging Env - $envvar - ${e} -  ${const String.fromEnvironment("firebase_api_key_android")} '
      '${const String.fromEnvironment("founders_version")}');


  AnalyticsService.init();


  runApp(MyApp());

  AnalyticsService.logAppOpen();
}

class MyApp extends StatelessWidget {
  final MyRouteObserver routeObserver = MyRouteObserver();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => GetStatusProvider()),
        ChangeNotifierProvider(create: (_) => GetSavedMediaProvider()),
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        home: const SplashScreen(),
      ),
    );
  }
}
