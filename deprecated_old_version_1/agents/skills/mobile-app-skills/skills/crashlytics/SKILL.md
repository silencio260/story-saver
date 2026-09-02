---
name: crashlytics
description: Host-level Firebase Crashlytics wiring for crash + non-fatal error reporting (framework, engine, async, BLoC). Android-only.
---

# Crashlytics

## Overview

Firebase Crashlytics for crash and non-fatal error reporting. Wired **host-level**
directly on `firebase_core` — not through the starter kit. The `genrevibes_starter_kit`
package *declares* `firebase_crashlytics` but ships **no Crashlytics code** (its
`StarterKit.initialize()` never sets `FlutterError.onError` or any zone handler), so
wiring it host-side avoids activating the whole kit (ads/IAP/PostHog/auth) just to get
crash reporting. In `smart_launcher_app` the kit's `firebase_crashlytics` line is commented
out for this reason.

See also: [Firebase Infrastructure](../firebase-infrastructure/SKILL.md) for core init,
[Error Handling](../error-handling/SKILL.md) for the in-app `Either<Failure, T>` flow
(orthogonal — that's expected control flow, Crashlytics is for *unexpected* crashes).

## Prerequisites

- `Firebase.initializeApp()` already running (see Firebase Infrastructure skill).
- `firebase_core` in `pubspec.yaml`.
- `google-services.json` present at `android/app/`.
- Android-only target. No `GoogleService-Info.plist` / iOS app.

## The four wiring points

### 1. Dependency — `pubspec.yaml`

```yaml
  firebase_core: ^3.6.0
  firebase_crashlytics: ^4.1.3   # compatible with firebase_core ^3.x
```

### 2. Gradle plugin (uploads mapping/symbol files so stack traces deobfuscate)

```kotlin
// android/settings.gradle.kts — plugins { } block
id("com.google.gms.google-services") version "4.4.2" apply false
id("com.google.firebase.crashlytics") version "3.0.2" apply false
```

```kotlin
// android/app/build.gradle.kts — plugins { } block (after google-services)
id("com.google.gms.google-services")
id("com.google.firebase.crashlytics")
```

### 3. Error handlers — `main.dart`

`main()` body runs inside `runZonedGuarded`, after `Firebase.initializeApp`:

```dart
runZonedGuarded<Future<void>>(() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Keep local dev crashes out of the dashboard; only release builds report.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Framework errors (build/layout/paint).
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Low-level platform/engine errors.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ...rest of bootstrap, then runApp(...)
}, (error, stack) {
  // Uncaught async / Dart errors the framework hooks miss.
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
});
```

Three capture paths: framework (`FlutterError.onError`), engine
(`PlatformDispatcher.onError`), uncaught async (the zone handler).

### 4. BLoC/Cubit errors — `bloc_observer.dart`

`AppBlocObserver.onError` reports Cubit/Bloc exceptions as **non-fatals**:

```dart
@override
void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
  FirebaseCrashlytics.instance.recordError(
    error, stackTrace, reason: '${bloc.runtimeType} error', fatal: false,
  );
  super.onError(bloc, error, stackTrace);
}
```

## Collection is disabled in debug

`setCrashlyticsCollectionEnabled(!kDebugMode)` keeps local dev crashes out of the
dashboard — only release builds report. To force a test crash in a release build:
`FirebaseCrashlytics.instance.crash()`.

## Obfuscation

For release/obfuscated builds, pass `--split-debug-info` / `--obfuscate` **consistently**
so the Crashlytics Gradle plugin can upload the symbol files; otherwise release stack
traces stay obfuscated in the dashboard.

## Interaction Map

- **Firebase core init** → must complete before any Crashlytics call.
- **Error Handling (`Either`/`Failure`)** → handles *expected* errors; Crashlytics is for
  *unexpected* crashes/exceptions. They don't overlap.
- **BLoC layer** → `AppBlocObserver` funnels Cubit/Bloc exceptions in as non-fatals.

## Checklist

- [ ] `firebase_crashlytics` in `pubspec.yaml`
- [ ] `com.google.firebase.crashlytics` plugin in `settings.gradle.kts` (apply false) + `app/build.gradle.kts` (applied)
- [ ] `main()` wrapped in `runZonedGuarded` with all three handlers
- [ ] `setCrashlyticsCollectionEnabled(!kDebugMode)`
- [ ] `AppBlocObserver.onError` records non-fatals
- [ ] Release build verified: a forced crash appears in the Firebase console
- [ ] `--split-debug-info`/`--obfuscate` consistent if shipping obfuscated
