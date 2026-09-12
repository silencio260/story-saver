import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes_manager.dart';
import 'config/theme_manager.dart';
import 'container_injector.dart';
import 'core/utils/app_strings.dart';
import 'core/utils/global_navigation_key.dart';
import 'features/analytics/data/services/analytics_service.dart';
import 'features/analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import 'features/analytics/presentation/widgets/analytics_scope.dart';
import 'features/monetization/presentation/bloc/ads_bloc/ads_bloc.dart';
import 'features/monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import 'features/navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import 'features/onboarding/presentation/bloc/onboarding_bloc/onboarding_bloc.dart';
import 'features/permissions/presentation/bloc/permissions_bloc/permissions_bloc.dart';
import 'features/saved_media/data/services/auto_save_service.dart';
import 'features/saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc/settings_bloc.dart';
import 'features/splash/presentation/bloc/splash_bloc/splash_bloc.dart';
import 'features/statuses/presentation/bloc/status_bloc/status_bloc.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      AnalyticsService.track('app_lifecycle_changed', {'state': state.name}),
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(AnalyticsService.drainPending());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    AutoSaveService.checkAndResumeDevMode();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AnalyticsBloc>(
        create: (_) => sl<AnalyticsBloc>()..add(const AnalyticsStarted()),
      ),
      BlocProvider<IapBloc>(
        create: (_) => sl<IapBloc>()..add(const IapStarted()),
      ),
      BlocProvider<AdsBloc>(create: (_) => sl<AdsBloc>()),
      BlocProvider<NavigationBloc>(create: (_) => sl()),
      BlocProvider<OnboardingBloc>(create: (_) => sl()),
      BlocProvider<PermissionsBloc>(create: (_) => sl()),
      BlocProvider<SavedMediaBloc>(create: (_) => sl()),
      BlocProvider<SettingsBloc>(create: (_) => sl()),
      BlocProvider<SplashBloc>(create: (_) => sl()),
      BlocProvider<StatusBloc>(create: (_) => sl()),
    ],
    child: BlocListener<IapBloc, IapState>(
      listenWhen:
          (previous, current) =>
              previous.isPremium != current.isPremium ||
              previous.status != current.status,
      listener: (context, state) {
        if (state.isPremium) {
          context.read<AdsBloc>().add(const AdsDisabled());
        } else if (state.status == IapViewStatus.ready) {
          context.read<AdsBloc>().add(const AdsStarted());
        }
      },
      child: AnalyticsScope(
        child: MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeManager.lightTheme,
          initialRoute: Routes.splash,
          onGenerateRoute: AppRouter.getRoute,
          navigatorKey: myGlobalNavigatorKey,
          navigatorObservers: AnalyticsScope.navigatorObservers,
        ),
      ),
    ),
  );
}
