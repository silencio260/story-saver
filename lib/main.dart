import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Provider/PermissionProvider.dart';
import 'package:storysaver/Provider/topNavProvider.dart';
import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/splash_screen.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Utils/globalNavigationKey.dart';
import 'package:storysaver/Widget/MyRouteObserver.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  print('ensureInitialized');

  String envvar = const String.fromEnvironment("founders_version");
  String e = AppConstants.SAVED_STORY_PATH;
  debugPrint('#### Staging Env - $envvar - ${e} -  ${const String.fromEnvironment("firebase_api_key_android")} '
      '${const String.fromEnvironment("founders_version")}');

  //Init MediaStore
  await MediaStore.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => TopNavProvider()),
        ChangeNotifierProvider(create: (_) => GetStatusProvider()),
        ChangeNotifierProvider(create: (_) => GetSavedMediaProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Colors.green, // Set the custom primary color
          ),
        ),
        navigatorObservers: [routeObserver],
        navigatorKey: myGlobalNavigatorKey,
        home: const SplashScreen(),
      ),
    );
  }
}
