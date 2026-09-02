---
name: gdpr-compliance
description: Consent dialogs, data handling, and privacy compliance via starter kit
---

# GDPR Compliance

## Overview

GDPR compliance handles consent dialogs and data privacy using the starter kit's `GdprRepository`.

## Implementation

```dart
final gdprRepo = StarterKit.sl<GdprRepository>();

// Check consent status
final hasConsent = await gdprRepo.hasUserConsented();

// Show consent dialog
await gdprRepo.showConsentDialog();

// Reset consent
await gdprRepo.resetConsent();
```

### Show on First Launch

```dart
// In splash/onboarding flow
if (!await gdprRepo.hasUserConsented()) {
  await gdprRepo.showConsentDialog();
}
```

## Privacy Policy

Every app published to the Play Store needs a privacy policy URL that matches its
Play **Data safety** declaration field-for-field (mismatches are themselves a violation).

Generate a baseline with the free checkbox-based generator:

- https://app-privacy-policy-generator.firebaseapp.com

It covers the standard SDKs (Firebase, Crashlytics, AdMob, etc.). After generating,
hand-add disclosures the generator does not template:

- **Mixpanel Session Replay** — that screen interactions are recorded, what is masked,
  and retention. Keep "mask all text and images" on by default.
- **Local-only sensitive data** — vault / app-lock / app-hider PINs and patterns are
  stored on-device and not transmitted.
- **Sensitive permissions** — e.g. Usage Access (App Lock watcher), and why it is used.

## Interaction Map

- **Onboarding** → Show consent during onboarding
- **Ads** → Personalized vs non-personalized ads based on consent
- **Analytics** → Respect consent for tracking
- **Settings** → Privacy settings tile

## Checklist

- [ ] Consent dialog shown on first launch
- [ ] Consent status persisted
- [ ] Ads respect consent preference
- [ ] Settings includes privacy management
