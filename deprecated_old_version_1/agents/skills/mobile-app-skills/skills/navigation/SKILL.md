---
name: navigation
description: Route management using named routes, AppRouter, and route configuration
---

# Navigation

## Overview

Navigation uses Flutter's `onGenerateRoute` with a centralized `AppRouter` class. All routes are defined as constants in a `Routes` class. The starter kit provides a `DoubleTapToExit` wrapper.

## Architecture

```
config/
└── routes_manager.dart    # Routes constants + AppRouter
```

## Implementation

### Route Constants

```dart
class Routes {
  static const String splash = "/splash";
  static const String onboarding = "/onboarding";
  static const String auth = "/auth";
  static const String home = "/home";
  static const String settings = "/settings";
  static const String chat = "/chat";
  // ... add per feature
}
```

### AppRouter

```dart
class AppRouter {
  static Route? getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      // ... other routes
      default:
        return null;
    }
  }
}
```

### Wire in MyApp

```dart
MaterialApp(
  initialRoute: Routes.splash,
  onGenerateRoute: AppRouter.getRoute,
)
```

### Navigate

```dart
Navigator.pushNamed(context, Routes.home);
Navigator.pushReplacementNamed(context, Routes.home);
Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
```

### Pass Arguments

```dart
// Navigate with args
Navigator.pushNamed(context, Routes.chat, arguments: chatId);

// Receive in AppRouter
case Routes.chat:
  final chatId = routeSettings.arguments as String;
  return MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId));
```

## Starter Kit Integration

Use `DoubleTapToExit` on the home screen:

```dart
StarterKit.doubleTapToExit(child: HomeScreen());
```

## Interaction Map

- **Splash** → decides initial route (onboarding vs home)
- **Auth** → redirects to home on success
- **Onboarding** → redirects to home/auth on complete
- **Settings** → navigates to sub-pages
- **Deep Linking** → maps external links to routes

## Checklist

- [ ] `Routes` class with all route constants
- [ ] `AppRouter.getRoute()` handles all routes
- [ ] `MaterialApp` uses `onGenerateRoute`
- [ ] Arguments passed correctly where needed
- [ ] `DoubleTapToExit` wrapping home screen
