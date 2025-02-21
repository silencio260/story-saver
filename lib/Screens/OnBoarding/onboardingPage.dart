import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:storysaver/Screens/OnBoarding/onboarding_widget/onboarding_card.dart';



class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static final PageController _pageController = PageController(initialPage: 0);

  List<Widget> _onBoardingPages = [
    OnboardingCard(
      image: "assets/images/app-logo.png",
      title: 'Welcome to Sinau.io!',
      description: "Introducing the Learn. platfrom and providing a somethin",
      buttonText: 'Next',
      onPressed: () {
        _pageController.animateToPage(
            1,
            duration: Durations.long1,
            curve: Curves.linear
        );
      },
    ),
    OnboardingCard(
      image: "assets/images/app-logo.png",
      title: 'Welcome to Sinau.io! 2',
      description: "Introducing the Learn. platfrom and providing a somethin",
      buttonText: 'Next',
      onPressed: () {
        _pageController.animateToPage(
            2,
            duration: Durations.long1,
            curve: Curves.linear
        );
      },
    ),
    OnboardingCard(
      image: "assets/images/app-logo.png",
      title: 'Welcome to Sinau.io! 3',
      description: "Introducing the Learn. platfrom and providing a somethin",
      buttonText: 'Done',
      onPressed: () {

      },
    ),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: EdgeInsets.symmetric(vertical: 50),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: PageView(
                controller: _pageController,
                children: _onBoardingPages,
              )
          ),
          SmoothPageIndicator(
              controller: _pageController,
              count: _onBoardingPages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: Theme.of(context).colorScheme.primary,
              dotColor: Theme.of(context).colorScheme.secondary
            ),
            onDotClicked: (index) {
              _pageController.animateToPage(
                  index,
                  duration: Durations.long1,
                  curve: Curves.linear
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
