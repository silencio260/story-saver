---
name: onboarding
description: Multi-page intro flow using starter kit templates with customizable pages, dots, and callbacks
---

# Onboarding

## Overview

Onboarding provides a multi-page intro screen shown on first app launch. The starter kit provides ready-made templates (`standard`, `minimal`, `custom`) via `StarterKit.onboarding()`.

## Prerequisites

- Starter kit integrated (see `starter-kit/SKILL.md`)
- Onboarding images/assets prepared

## Architecture

For simple onboarding, no separate feature folder is needed — use starter kit directly. For custom onboarding with business logic:

```
features/onboarding/
├── presentation/
│   ├── screens/
│   │   └── onboarding_screen.dart
│   └── widgets/
│       └── onboarding_page.dart
└── domain/
    └── usecases/
        └── complete_onboarding_usecase.dart   # Saves "onboarding_done" flag
```

## Implementation

### Using Starter Kit (Recommended)

```dart
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StarterKit.onboarding(
      template: OnboardingTemplateType.standard,
      pages: [
        OnboardingPageModel(
          title: 'Welcome',
          description: 'Discover amazing features',
          imagePath: 'assets/onboarding/welcome.png',
          titleColor: Colors.blue,
        ),
        OnboardingPageModel(
          title: 'AI Powered',
          description: 'Powered by cutting-edge AI',
          imagePath: 'assets/onboarding/ai.png',
        ),
        OnboardingPageModel(
          title: 'Get Started',
          description: 'Sign up and start exploring',
          customWidget: MyCustomHeroWidget(),
        ),
      ],
      onComplete: () {
        // Save onboarding completion flag
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('onboarding_complete', true);
        });
        Navigator.pushReplacementNamed(context, Routes.home);
      },
      onSkip: () {
        Navigator.pushReplacementNamed(context, Routes.home);
      },
      activeDotColor: AppColors.primary,
      nextText: 'Next',
      completeText: 'Get Started',
    );
  }
}
```

### Splash → Onboarding Decision

```dart
// In splash screen
final prefs = await SharedPreferences.getInstance();
final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
if (onboardingDone) {
  Navigator.pushReplacementNamed(context, Routes.home);
} else {
  Navigator.pushReplacementNamed(context, Routes.onboarding);
}
```

## Interaction Map

- **Splash** → Decides whether to show onboarding or home
- **Tracking** → `isFirstTimeUser()` aligns with onboarding state
- **Analytics** → Log `onboarding_started`, `onboarding_completed`, `onboarding_skipped`
- **Auth** → Can redirect to auth screen from onboarding completion

## Checklist

- [ ] Onboarding pages defined with titles, descriptions, images
- [ ] `StarterKit.onboarding()` called with correct template
- [ ] `onComplete` saves completion flag and navigates
- [ ] `onSkip` handles skip properly
- [ ] Splash screen checks onboarding flag
- [ ] Route defined in `routes_manager.dart`
- [ ] Analytics events logged
