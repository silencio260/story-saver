---
name: profile
description: User profile management with Firestore persistence and starter kit database module
---

# Profile

## Overview

Profile manages user data (display name, avatar, preferences) and usage tracking. Leverages the starter kit's database module for Firestore `UserProfileEntity`.

## Architecture

```
features/profile/
├── profile_injector.dart
├── data/
│   ├── models/profile_model.dart
│   └── repositories/profile_repo.dart
├── domain/
│   ├── entities/profile_entity.dart
│   ├── repositories/profile_base_repo.dart
│   └── usecases/
│       ├── get_profile_usecase.dart
│       └── update_profile_usecase.dart
└── presentation/
    ├── bloc/profile_bloc/
    ├── screens/profile_screen.dart
    └── widgets/
```

## Firebase / Cloud

- **Firestore:** `users/{uid}` — Profile document with name, email, avatar, subscription status, usage counters

## Starter Kit Integration

The starter kit's `UserProfileRepository` and `UserProfileEntity` handle:
- Subscription tracking
- Usage counter management
- Profile CRUD operations

```dart
await StarterKit.initialize(
  userProfileRepository: MyUserProfileRepository(),
);
```

## Interaction Map

- **Auth** → Profile created on sign-up
- **IAP** → Subscription status in profile
- **Quota** → Usage counters in profile
- **Push Notifications** → User ID from profile
- **Analytics** → User properties from profile

## Checklist

- [ ] Profile entity with required fields
- [ ] Firestore document structure defined
- [ ] Profile screen with edit functionality
- [ ] Usage tracking integrated
- [ ] Starter kit `UserProfileRepository` provided
