---
name: remote-config
description: Firebase Remote Config for feature flags, A/B testing, and force update
---

# Remote Config

## Overview

Remote Config uses Firebase Remote Config via the starter kit for feature flags, A/B testing, force update checks, and dynamic configuration.

## Canonical Template

When the user asks for a "remote config temp", "remote config template", or a Firebase Remote Config starter template, use:

```text
agents/mobile-app-skills/skills/remote-config/remote_config_template.json
```

This file is the canonical Firebase Remote Config template for GenRevibes apps. It is based on a Firebase Console export and includes the standard ad timing and app-open ad flags used by the starter kit. Copy it into the target app workflow as `remote_config_template.json`, then adjust app-specific values before importing or publishing in Firebase Remote Config.

Keep parameter keys stable unless the app code and starter kit readers are updated together.

## Implementation

```dart
final configRepo = StarterKit.sl<RemoteConfigRepository>();

// Fetch latest values
await configRepo.fetchAndActivate();

// Read values
final bool featureEnabled = configRepo.getBool('new_feature_enabled');
final String apiUrl = configRepo.getString('api_base_url');
final int minVersion = configRepo.getInt('min_app_version');
```

### Force Update Check

```dart
final minVersion = configRepo.getInt('min_app_version');
final currentVersion = /* get from package_info */;
if (currentVersion < minVersion) {
  showForceUpdateDialog();
}
```

## Interaction Map

- **Content Locking** → Feature flags for premium features
- **Ads** → Dynamic ad frequency settings
- **Paywall** → A/B test paywall designs
- **Splash** → Force update check on launch

## Checklist

- [ ] Remote Config defaults set in Firebase Console
- [ ] `remote_config_template.json` used as the starting Firebase Remote Config template
- [ ] `fetchAndActivate()` called on app launch
- [ ] Feature flags used for gradual rollouts
- [ ] Force update version check implemented
