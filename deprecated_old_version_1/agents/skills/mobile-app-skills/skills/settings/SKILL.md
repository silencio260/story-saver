---
name: settings
description: Dynamic settings screen using starter kit templates with grouped sections
---

# Settings

## Overview

Settings provides a dynamic settings page using the starter kit's `StarterKit.settings()` template. Supports `list` and `grouped` layouts with customizable sections and tiles.

## Implementation

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StarterKit.settings(
      template: SettingsTemplateType.grouped,
      title: 'Settings',
      sections: [
        SettingsSection(
          title: 'General',
          tiles: [
            SettingsTile(title: 'Dark Mode', icon: Icons.dark_mode, onTap: () {}),
            SettingsTile(title: 'Language', icon: Icons.language, subtitle: 'English', onTap: () {}),
            SettingsTile(title: 'Notifications', icon: Icons.notifications, onTap: () {}),
          ],
        ),
        SettingsSection(
          title: 'Account',
          tiles: [
            SettingsTile(title: 'Restore Purchases', icon: Icons.restore,
              onTap: () => StarterKit.iapBloc.add(const IapRestorePurchases())),
            SettingsTile(title: 'Privacy Policy', icon: Icons.lock, onTap: () {}),
            SettingsTile(title: 'Terms of Service', icon: Icons.description, onTap: () {}),
          ],
        ),
        SettingsSection(
          title: 'Support',
          tiles: [
            SettingsTile(title: 'Send Feedback', icon: Icons.feedback, onTap: () {}),
            SettingsTile(title: 'Rate App', icon: Icons.star, onTap: () {}),
            SettingsTile(title: 'Share App', icon: Icons.share, onTap: () {}),
          ],
        ),
      ],
    );
  }
}
```

## Interaction Map

- **IAP** → Restore purchases, manage subscription
- **Feedback** → Send feedback via `FeedbackRepository`
- **App Rating** → Trigger in-app review
- **Push Notifications** → Toggle notifications
- **Theming** → Toggle dark/light mode
- **GDPR** → Privacy settings
- **Localization** → Language selection

## Debug Section (Developer Mode)

When `kDebugMode` is active, a **DEVELOPER OPTIONS** section appears at the bottom of settings:

- **Clear Chat History**: Deletes all local conversation summaries and message history from `SharedPreferences`.
- **Reset Preferences**: Clears all `SharedPreferences` keys (Tone, Voice, Language, etc.) and reloads defaults.
- **Debug Premium**: 
  - **Effect**: Simulates a fully active paid subscription.
  - **Premium State Mirroring**: Updates `SubscriptionManager` and `UserProfileEntity.effectiveTier` to return `pro`.
  - **UI Changes**: 
    - Replaces the "Go Pro" card with a "Manage Subscription" section.
    - Updates Home Screen "PRO" badge (it becomes clickable and labeled "PRO").
    - Hides all Paywalls and Ads.
    - Enables all Premium Models and Features.

## Checklist

- [ ] Settings screen created using `StarterKit.settings()`
- [ ] Sections organized logically (General, Account, Support)
- [ ] Restore purchases connected to `IapBloc`
- [ ] Feedback, rating, sharing tiles wired
- [ ] Route defined in `routes_manager.dart`
