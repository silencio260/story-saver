import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  AnalyticsService.init();

  // Provider.of<GetSavedMediaProvider>(context, listen: false).loadVideos();
  // final getSavedMedia = GetSavedMediaProvider();
  // print('getSavedMedia');
  // await getSavedMedia.loadVideos();
  // print('getSavedMedia.loadVideos in main');

  runApp(MyApp());

  AnalyticsService.logAppOpen();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     home: SplashScreen(),
  //   );
  // }
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
