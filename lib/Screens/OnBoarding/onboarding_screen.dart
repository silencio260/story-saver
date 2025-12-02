import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Screens/home_page.dart';
import 'package:storysaver/Services/OnboardingManager.dart';
import 'package:storysaver/Services/analytics_service.dart';

class OnboardingScreen extends StatefulWidget {
  final bool forceShow;
  const OnboardingScreen({Key? key, this.forceShow = false}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;
  bool _isLoading = false;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: "Save Stories Instantly",
      description:
          "Download and save your favorite stories and status updates with just one tap.",
      imagePath: "assets/images/onboarding_1.png",
    ),
    OnboardingPageModel(
      title: "Organize Your Gallery",
      description:
          "Keep your saved media organized and easily accessible in your personal gallery.",
      imagePath: "assets/images/onboarding_2.png",
    ),
    OnboardingPageModel(
      title: "Unlock Premium Features",
      description:
          "Go Premium to remove ads, unlock unlimited downloads, and access exclusive features.",
      imagePath: "assets/images/onboarding_3.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _isLastPage = index == _pages.length - 1;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
              child: _isLastPage
                  ? SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(CustomColors.AppBarColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                await _completeOnboarding();
                              },
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Get Started",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _controller.jumpToPage(_pages.length - 1),
                          child: const Text(
                            "Skip",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        SmoothPageIndicator(
                          controller: _controller,
                          count: _pages.length,
                          effect: const WormEffect(
                            spacing: 12,
                            dotHeight: 10,
                            dotWidth: 10,
                            dotColor: Colors.black12,
                            activeDotColor: Color(CustomColors.AppBarColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          ),
                          child: const Text(
                            "Next",
                            style: TextStyle(
                                color: Color(CustomColors.AppBarColor),
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageModel page) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              page.imagePath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  page.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show Paywall and wait for it to close (or fail)
      // We don't enforce a strict timeout on the *viewing* duration,
      // but the loading state handles the "loading a bit" UX.
      await RevenueCatService().PresentRevenueCatPayWallIfNeeded();
    } catch (e) {
      print("Error showing paywall: $e");
    } finally {
      if (mounted) {
        // Track analytics
        await AnalyticsService.logOnboardingComplete();

        // Use Helper Class
        await OnboardingManager.setOnboardingSeen();

        // Navigate to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
