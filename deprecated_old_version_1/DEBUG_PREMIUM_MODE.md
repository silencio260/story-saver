# Debug Mode for Premium Access

## Quick Usage

To enable premium access during development/testing without an actual subscription:

```dart
import 'package:storysaver/Monetization/SubscriptionManager.dart';

// Anywhere in your app (e.g., in main.dart or a debug settings screen):
void main() {
  // ... your existing initialization code ...
  
  // Enable debug premium access (only works in development mode)
  SubscriptionManager().debugOverridePremium = true;
  
  // ... rest of your app ...
}
```

## How It Works

1. **Safety First**: The debug override ONLY works when your app is running in development mode (determined by `DevelopmentModeUtils.checkDevelopmentMode()`)
2. **Automatic**: Once enabled, all ad checks will automatically treat you as a premium user
3. **Real-time**: You can toggle it on/off at runtime - no need to restart the app
4. **Production Safe**: In release builds, this flag is ignored completely

## Example: Toggle in Settings

You can add a debug toggle in your settings screen:

```dart
if (DevelopmentModeUtils.checkDevelopmentMode()) {
  SwitchListTile(
    title: Text('Debug: Simulate Premium User'),
    subtitle: Text('Hide ads without subscription'),
    value: SubscriptionManager().debugOverridePremium,
    onChanged: (value) {
      setState(() {
        SubscriptionManager().debugOverridePremium = value;
      });
    },
  );
}
```

## What Gets Hidden

When `debugOverridePremium = true`:
- ✅ Banner ads won't load
- ✅ Interstitial ads won't show  
- ✅ Any premium-only features will be accessible
- ✅ Debug logs will show: "Debug override active - granting premium access"

## Disable for Production Testing

To test as a free user in development mode:

```dart
SubscriptionManager().debugOverridePremium = false;
```

## Environment Variables

Your existing development mode is controlled by:
- `kDebugMode` (Flutter's built-in debug mode)
- `founders_version` environment variable
- `development_mode` environment variable  
- `special_version_mode` environment variable

If ANY of these are true, the debug override can be activated.
