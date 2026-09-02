import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../config/routes_manager.dart';
import '../../../../core/utils/legacy_custom_colors.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../bloc/onboarding_bloc/onboarding_bloc.dart';
import '../l10n/onboarding_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.forceShow = false, super.key});

  final bool forceShow;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingPageModel> _pages = <_OnboardingPageModel>[
    _OnboardingPageModel(
      title: OnboardingStrings.firstTitle,
      description: OnboardingStrings.firstDescription,
      imagePath: 'assets/images/onboarding_1.png',
    ),
    _OnboardingPageModel(
      title: OnboardingStrings.secondTitle,
      description: OnboardingStrings.secondDescription,
      imagePath: 'assets/images/onboarding_2.png',
    ),
    _OnboardingPageModel(
      title: OnboardingStrings.thirdTitle,
      description: OnboardingStrings.thirdDescription,
      imagePath: 'assets/images/onboarding_3.png',
    ),
  ];

  final PageController _controller = PageController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<OnboardingBloc, OnboardingState>(
    listener: (context, state) {
      if (state.status == OnboardingViewStatus.completed) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
      } else if (state.status == OnboardingViewStatus.failure &&
          state.message != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message!)));
      }
    },
    child: BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isLastPage = state.pageIndex == _pages.length - 1;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged:
                        (index) => context.read<OnboardingBloc>().add(
                          OnboardingPageChanged(index),
                        ),
                    itemBuilder:
                        (context, index) =>
                            _OnboardingPage(page: _pages[index]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                    bottom: 50,
                    left: 20,
                    right: 20,
                  ),
                  child:
                      isLastPage
                          ? SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  CustomColors.AppBarColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _isLoading ? null : _complete,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                      : const Text(
                                        OnboardingStrings.start,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              TextButton(
                                onPressed:
                                    () => _controller.jumpToPage(
                                      _pages.length - 1,
                                    ),
                                child: const Text(
                                  OnboardingStrings.skip,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  activeDotColor: Color(
                                    CustomColors.AppBarColor,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.easeInOut,
                                    ),
                                child: const Text(
                                  OnboardingStrings.next,
                                  style: TextStyle(
                                    color: Color(CustomColors.AppBarColor),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Future<void> _complete() async {
    setState(() => _isLoading = true);
    final iapBloc = context.read<IapBloc>();
    try {
      final paywallFinished = iapBloc.stream.firstWhere(
        (state) =>
            state.status == IapViewStatus.ready ||
            state.status == IapViewStatus.failure,
      );
      iapBloc.add(const IapPaywallRequested());
      await paywallFinished.timeout(const Duration(seconds: 5));
    } catch (_) {
      // Preserve the original behavior: onboarding continues if IAP times out.
    }
    if (!mounted) return;
    context.read<AnalyticsBloc>().add(
      const AnalyticsEventLogged(
        AnalyticsEventEntity(name: 'onboarding_complete'),
      ),
    );
    context.read<OnboardingBloc>().add(const OnboardingCompleted());
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _OnboardingPageModel page;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Image.asset(page.imagePath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 30),
        Expanded(
          flex: 2,
          child: Column(
            children: <Widget>[
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

class _OnboardingPageModel {
  const _OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;
}
