---
name: quota-rate-limiting
description: Usage quotas and rate limits per feature for free vs premium users
---

# Quota & Rate Limiting

## Overview

The quota system tracks usage per feature (chat messages, image generations, etc.) and enforces limits for free users. Subscribers have unlimited or elevated limits. Usage data is stored in the user profile via the starter kit's database module.

## Architecture

```
features/quota/
├── quota_injector.dart
├── data/
│   ├── models/quota_model.dart
│   └── repositories/quota_repo.dart
├── domain/
│   ├── entities/quota_entity.dart
│   ├── repositories/quota_base_repo.dart
│   └── usecases/
│       ├── check_quota_usecase.dart
│       ├── increment_usage_usecase.dart
│       └── reset_quota_usecase.dart
└── presentation/
    └── bloc/quota_bloc/
```

## Implementation

```dart
// Check quota before action
final canProceed = await checkQuotaUseCase('image_generation');
canProceed.fold(
  (failure) => showPaywall(),  // Quota exceeded
  (remaining) => generateImage(),
);

// Increment after action
await incrementUsageUseCase('image_generation');
```

## Firebase / Cloud

- **Firestore:** `users/{uid}/usage` — Usage counters per feature
- **Starter Kit Database:** `UsageType` enum for tracking types

## Interaction Map

- **Content Locking** → `ContentGate` checks quota
- **IAP** → Subscribers bypass limits
- **Profile** → Usage counters stored in user profile
- **Remote Config** → Quota limits configurable remotely
- **Tracking** → Usage patterns inform monetization

## Checklist

- [ ] Quota entities and use cases defined
- [ ] Usage counters persisted in Firestore
- [ ] Free tier limits enforced
- [ ] Subscriber bypass implemented
- [ ] Daily/monthly reset logic
- [ ] Remaining quota displayed to user
