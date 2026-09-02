---
name: splash-screen
description: Animated splash screen with initialization logic and routing decisions
---

# Splash Screen

## Overview

The splash screen shows branding while initializing dependencies, then routes to onboarding (first time) or home (returning user).

## Architecture

```
features/splash/
└── presentation/
    └── screens/
        └── splash_screen.dart
```

## Implementation

```dart
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Wait for any async initialization
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    // 3. Check force update via remote config
    // final configRepo = StarterKit.sl<RemoteConfigRepository>();

    // 4. Route
    if (!onboardingDone) {
      Navigator.pushReplacementNamed(context, Routes.onboarding);
    } else {
      Navigator.pushReplacementNamed(context, Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset('assets/logo.png')),
    );
  }
}
```

## Interaction Map

- **Onboarding** → First-time routing
- **Auth** → Can route to auth if not logged in
- **Remote Config** → Force update check
- **GDPR** → Consent dialog before proceeding

## Checklist

- [ ] Splash screen with branding
- [ ] Async initialization during splash
- [ ] Onboarding check for first-time users
- [ ] Force update check via remote config
- [ ] Route set as initial route
