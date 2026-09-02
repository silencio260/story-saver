---
name: app-rating
description: In-app review prompts at strategic moments
---

# App Rating

## Overview

App rating triggers the native in-app review dialog at strategic moments (after positive actions, returning users, etc.) via the starter kit's `AppRatingRepository`.

## Implementation

```dart
final ratingRepo = StarterKit.sl<AppRatingRepository>();

// Request review (respects platform rate limits)
await ratingRepo.requestReview();
```

### Strategic Timing

```dart
// After completing a positive action (download, generation, etc.)
void onPositiveAction() {
  final targeting = UserTargetingManager.instance;
  if (targeting.isReturningUser() && targeting.getEngagementLevel() == UserEngagementLevel.HIGH) {
    ratingRepo.requestReview();
  }
}
```

## Interaction Map

- **Tracking** → Triggered for engaged/returning users
- **Settings** → "Rate App" tile
- **Analytics** → Log when review requested

## Checklist

- [ ] `in_app_review` configured
- [ ] Review requested after positive user actions
- [ ] Targeting logic avoids over-prompting
- [ ] Settings tile links to app store page
