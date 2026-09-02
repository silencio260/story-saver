import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Screens/home_page.dart';
import 'package:storysaver/Services/analytics_service.dart';
import 'package:storysaver/Screens/Onboarding/onboarding_screen.dart';
import 'package:storysaver/Services/OnboardingManager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Provider.of<GetSavedMediaProvider>(context, listen: false)
        .loadVMediaInStaggeredBatches();

    navigate();
  }

  void navigate() {
    Future.delayed(
      const Duration(seconds: 2),
      () async {
        AnalyticsService.logGotoHomePage();

        final bool hasSeenOnboarding =
            await OnboardingManager.hasSeenOnboarding();

        if (mounted) {
          if (hasSeenOnboarding == false) {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(builder: (_) => const OnboardingScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
      child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          child: Image(
            image: AssetImage("assets/images/app-logo.png"),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          )),
    ));
  }
}
