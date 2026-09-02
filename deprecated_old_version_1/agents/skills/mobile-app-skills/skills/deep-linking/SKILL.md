---
name: deep-linking
description: Universal links, dynamic links, and external URL routing
---

# Deep Linking

## Overview

Deep linking maps external URLs to specific screens in the app. Supports Universal Links (iOS), App Links (Android), and Firebase Dynamic Links.

## Implementation

### Route Handling

```dart
// In AppRouter, handle deep link parameters
case Routes.chat:
  final args = routeSettings.arguments;
  if (args is Map<String, String>) {
    return MaterialPageRoute(
      builder: (_) => ChatScreen(sessionId: args['sessionId']),
    );
  }
```

### Firebase Dynamic Links

```dart
// Listen for dynamic links
FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
  final deepLink = dynamicLinkData.link;
  // Parse and navigate
  Navigator.pushNamed(context, deepLink.path);
});
```

## Platform Configuration

### iOS — `Info.plist` and Associated Domains
### Android — `AndroidManifest.xml` intent filters

## Interaction Map

- **Navigation** → Deep links resolve to named routes
- **Auth** → May require authentication before deep link content
- **Push Notifications** → Notification taps use deep links

## Checklist

- [ ] URL patterns defined
- [ ] Platform configurations set (iOS/Android)
- [ ] Deep link parsing in app
- [ ] Auth guard on protected deep links
