import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Screens/home_page.dart';

class OnboardingScreen extends StatefulWidget {
  final bool forceShow;
  const OnboardingScreen({Key? key, this.forceShow = false}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

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
      body: Column(
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
            padding: const EdgeInsets.only(bottom: 50), // Increased bottom padding
            child: SafeArea(
              child: _isLastPage
                  ? Container(
                      height: 80,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(CustomColors.AppBarColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          await _completeOnboarding();
                        },
                        child: const Text(
                          "Start Free Trial",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      height: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _controller.jumpToPage(_pages.length - 1),
                            child: const Text(
                              "SKIP",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Center(
                            child: SmoothPageIndicator(
                              controller: _controller,
                              count: _pages.length,
                              effect: const WormEffect(
                                spacing: 16,
                                dotColor: Colors.black26,
                                activeDotColor: Color(CustomColors.AppBarColor),
                              ),
                              onDotClicked: (index) =>
                                  _controller.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            ),
                            child: const Text(
                              "NEXT",
                              style: TextStyle(
                                  color: Color(CustomColors.AppBarColor),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageModel page) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page.imagePath,
            height: 350,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    // Navigate to Home
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );

    // Show Paywall
    RevenueCatService().PresentRevenueCatPayWallIfNeeded();
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
