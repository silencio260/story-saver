---
name: new
description: Step-by-step guide for creating a new Flutter project with Clean Architecture + Starter Kit from scratch
---

# Create New Project

## Overview

This skill provides the complete workflow for scaffolding a new Flutter project following GenRevibes architecture patterns, from `flutter create` to first running feature.

## Step 1: Create Flutter Project

```bash
flutter create --org com.genrevibes your_app_name
cd your_app_name
```

## Step 2: Set Up Project Structure

Create the standard folder structure:

```bash
# Core
mkdir -p lib/src/config
mkdir -p lib/src/core/{api,error,helpers,network,usecase,utils,widgets}

# First feature (example)
mkdir -p lib/src/features/home/{data/{datasources/remote,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc/home_bloc,screens,widgets}}

# Container
touch lib/src/container_injector.dart
touch lib/src/my_app.dart
touch lib/bloc_observer.dart
```

## Step 3: Copy Config Templates

From the `agents/templates/` directory:

```bash
# Environment configs
cp -r agents/templates/env/ ./env/
cp agents/templates/env/env.example.json ./env.example.json

# IDE configs
cp -r agents/templates/.run/ ./.run/
cp -r agents/templates/.vscode/ ./.vscode/
```

Fill in API keys in `env/dev.json`.

## Step 4: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7
  get_it: ^9.2.0
  dartz: ^0.10.1
  dio: ^5.9.0
  internet_connection_checker: ^1.0.0+1
  shared_preferences: ^2.5.4
  path_provider: ^2.1.5

  # Starter Kit
  starter_kit:
    path: packages/starter_kit

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Step 5: Copy Starter Kit

```bash
mkdir -p packages
cp -r /path/to/starter_kit packages/starter_kit
flutter pub get
```

## Step 6: Set Up Core Files

Create these core files (use the patterns defined in `ARCHITECTURE_ANALYSIS.md`):

1. `core/usecase/base_usecase.dart` — Abstract `BaseUseCase<Output, Input>`
2. `core/error/failure.dart` — All Failure subclasses
3. `core/error/error_handler.dart` — Exception → Failure converter
4. `core/network/network_info.dart` — Connectivity checker
5. `core/helpers/dio_helper.dart` — HTTP client wrapper
6. `core/utils/app_colors.dart` — Color constants
7. `core/utils/app_strings.dart` — String constants
8. `config/routes_manager.dart` — Routes + AppRouter
9. `config/theme_manager.dart` — ThemeData

## Step 7: Wire Up DI Container

```dart
// container_injector.dart
final sl = GetIt.instance;

void initApp() {
  initCore();
  // initFeature1();
  // initFeature2();
}

void initCore() {
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(InternetConnectionChecker()),
  );
  sl.registerLazySingleton<DioHelper>(() => DioHelper());
}
```

## Step 8: Set Up main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StarterKit.initialize(supportEmail: 'support@yourapp.com');
  initApp(); // DI container
  Bloc.observer = MyBlocObserver();
  runApp(const MyApp());
}
```

## Step 9: Set Up MyApp

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: StarterKit.iapBloc),
        BlocProvider.value(value: StarterKit.adsBloc),
        BlocProvider.value(value: StarterKit.analyticsBloc),
        // App blocs added as features are created
      ],
      child: MaterialApp(
        title: 'Your App',
        theme: ThemeManager.lightTheme(),
        darkTheme: ThemeManager.darkTheme(),
        initialRoute: Routes.splash,
        onGenerateRoute: AppRouter.getRoute,
      ),
    );
  }
}
```

## Step 10: Build First Feature

Follow the implementation guidelines in `ARCHITECTURE_ANALYSIS.md`:

1. Create domain layer (entities → repo interface → use case → mapper)
2. Create data layer (models → data source → repo implementation)
3. Create presentation layer (events → states → BLoC → screen)
4. Wire DI (feature injector → register in container)
5. Add route

## Step 11: Configure Firebase

```bash
flutterfire configure
```

## Step 12: Start Retention Tracking

```dart
// In main.dart after StarterKit.initialize()
final analytics = AnalyticsService(StarterKit.analyticsBloc);
await UserTargetingManager.startTracking(analytics);
```

## New Project Checklist

- [ ] `flutter create` with correct org
- [ ] Folder structure created
- [ ] Env configs copied and filled
- [ ] IDE configs copied
- [ ] Dependencies added to `pubspec.yaml`
- [ ] Starter kit copied to `packages/`
- [ ] Core files created (base usecase, failures, network info, etc.)
- [ ] DI container set up
- [ ] `main.dart` with Firebase + StarterKit + DI
- [ ] `MyApp` with MultiBlocProvider + MaterialApp
- [ ] Firebase configured via FlutterFire CLI
- [ ] First feature built end-to-end
- [ ] Retention tracking started
- [ ] `.gitignore` updated (include `env/`)
- [ ] `env.example.json` committed
