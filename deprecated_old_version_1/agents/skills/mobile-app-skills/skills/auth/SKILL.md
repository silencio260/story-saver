---
name: auth
description: Firebase Auth sign-in/sign-up with Clean Architecture, BLoC, and starter kit integration
---

# Authentication

## Overview

Authentication handles user sign-in and sign-up using Firebase Auth. The system auto-detects whether a user is new or existing based on email. The starter kit provides an `AuthRepository` interface.

## Prerequisites

- Firebase project configured (see `skills/firebase-infrastructure/SKILL.md`)
- `firebase_auth` dependency (via starter kit)
- Starter kit integrated with `authRepository` provided

## Architecture

```
features/auth/
├── auth_injector.dart
├── data/
│   ├── datasources/
│   │   └── remote/
│   │       └── auth_remote_data_source.dart
│   ├── models/
│   │   └── user_model.dart
│   └── repositories/
│       └── auth_repo.dart
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   ├── repositories/
│   │   └── auth_base_repo.dart
│   └── usecases/
│       ├── sign_in_usecase.dart
│       ├── sign_up_usecase.dart
│       ├── sign_out_usecase.dart
│       └── get_current_user_usecase.dart
└── presentation/
    ├── bloc/
    │   └── auth_bloc/
    │       ├── auth_bloc.dart
    │       ├── auth_event.dart
    │       └── auth_state.dart
    ├── screens/
    │   └── auth_screen.dart
    └── widgets/
        └── auth_form.dart
```

## Implementation Steps

### 1. Domain Layer

```dart
// Entity
class UserEntity extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  const UserEntity({required this.uid, this.email, this.displayName});
}

// Repository Interface
abstract class AuthBaseRepo {
  Future<Either<Failure, UserEntity>> signIn(SignInParams params);
  Future<Either<Failure, UserEntity>> signUp(SignUpParams params);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
```

### 2. Data Layer

```dart
class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }
}
```

### 3. BLoC Events & States

```dart
// Events
class AuthSignIn extends AuthEvent { final String email, password; }
class AuthSignUp extends AuthEvent { final String email, password, name; }
class AuthSignOut extends AuthEvent {}
class AuthCheckStatus extends AuthEvent {}

// States
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { final UserEntity user; }
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState { final String message; }
```

## Starter Kit Integration

Provide your auth repository to the starter kit:

```dart
await StarterKit.initialize(
  authRepository: MyAuthRepository(),
);
```

## Firebase / Cloud

- **Firestore**: Creates user profile document on sign-up at `users/{uid}`
- **Firebase Auth**: Handles email/password, Google Sign-In, Apple Sign-In

## Interaction Map

- **Profile** → Created on successful sign-up
- **Analytics** → Logs `sign_in`, `sign_up` events
- **Push Notifications** → Sets user ID for targeted notifications
- **IAP** → Restores purchases for authenticated user
- **Tracking** → `isFirstTimeUser()` checks after auth

## Checklist

- [ ] Auth feature folder structure created
- [ ] Domain entities, repositories, use cases defined
- [ ] Data sources implement Firebase Auth
- [ ] BLoC handles sign-in, sign-up, sign-out, check status
- [ ] Auth screen UI with form validation
- [ ] User profile created in Firestore on sign-up
- [ ] Auth repository provided to StarterKit
- [ ] Analytics events logged for auth actions
