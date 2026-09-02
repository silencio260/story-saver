import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../domain/models/onboarding_page_model.dart';

enum OnboardingTemplateType { standard, minimal, custom }

/// Reusable Onboarding View with Template Support
class OnboardingView extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final OnboardingTemplateType templateType;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final Function(int)? onPageChange;

  // Customization
  final Color activeDotColor;
  final Color inactiveDotColor;
  final String nextButtonText;
  final String skipButtonText;
  final String completeButtonText;

  const OnboardingView({
    super.key,
    required this.pages,
    this.templateType = OnboardingTemplateType.standard,
    this.onComplete,
    this.onSkip,
    this.onPageChange,
    this.activeDotColor = Colors.blue,
    this.inactiveDotColor = Colors.grey,
    this.nextButtonText = 'Next',
    this.skipButtonText = 'Skip',
    this.completeButtonText = 'Get Started',
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            if (widget.onSkip != null)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    widget.skipButtonText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  widget.onPageChange?.call(index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(widget.pages[index]);
                },
              ),
            ),

            // Bottom Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageModel page) {
    switch (widget.templateType) {
      case OnboardingTemplateType.custom:
        // Fully host-driven page: render the supplied widget if present,
        // otherwise fall back to the standard layout below.
        if (page.customWidget != null) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: page.customWidget!,
          );
        }
        return _buildStandardPage(page);
      case OnboardingTemplateType.minimal:
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                page.title,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: page.titleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: page.descriptionColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case OnboardingTemplateType.standard:
        return _buildStandardPage(page);
    }
  }

  Widget _buildStandardPage(OnboardingPageModel page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page.imagePath != null)
            Expanded(
              child: page.imagePath!.endsWith('.json')
                  ? Lottie.asset(page.imagePath!)
                  : Image.asset(page.imagePath!),
            ),
          if (page.customWidget != null) Expanded(child: page.customWidget!),

          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: page.titleColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: page.descriptionColor ?? Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLastPage = _currentPage == widget.pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots Indicator
          Row(
            children: List.generate(
              widget.pages.length,
              (index) => Container(
                margin: const EdgeInsets.only(right: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color:
                      _currentPage == index
                          ? widget.activeDotColor
                          : widget.inactiveDotColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Action Button
          ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                widget.onComplete?.call();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              isLastPage ? widget.completeButtonText : widget.nextButtonText,
            ),
          ),
        ],
      ),
    );
  }
}
