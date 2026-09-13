import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_system_ui/genrevibes_system_ui.dart';

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
import 'features/monetization/data/services/subscription_service.dart';
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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  IapBloc? _iap;
  String? _lastIapMessage;

  void _onAccessChanged() {
    final bloc = _iap;
    if (bloc != null && !bloc.isClosed) {
      bloc.add(IapAccessChanged(SubscriptionManager().isPremium));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SubscriptionManager().addListener(_onAccessChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      AnalyticsService.track('app_lifecycle_changed', {'state': state.name}),
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(AnalyticsService.drainPending());
      unawaited(_refreshNotificationZone());
    }
  }

  Future<void> _refreshNotificationZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 2),
      );
      final scheduler = sl<LocalNotificationScheduler>();
      if (scheduler is LocalNotificationTimeZoneUpdater) {
        await (scheduler as LocalNotificationTimeZoneUpdater).updateTimeZone(
          zone,
        );
      }
    } on Object {
      // Retain the last working zone when the platform cannot supply a new one.
    }
  }

  @override
  void dispose() {
    SubscriptionManager().removeListener(_onAccessChanged);
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
        create: (_) => _iap = sl<IapBloc>()..add(const IapStarted()),
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
              previous.status != current.status ||
              previous.message != current.message,
      listener: (context, state) {
        if (state.message != null && state.message != _lastIapMessage) {
          _messengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
        _lastIapMessage = state.message;
        if (state.isPremium) {
          context.read<AdsBloc>().add(const AdsDisabled());
        } else if (state.status == IapViewStatus.ready) {
          context.read<AdsBloc>().add(const AdsStarted());
        }
      },
      child: AnalyticsScope(
        // Hidden on every screen unless the screen shows it with
        // NavigationBarVisibility; the observer tells it which screen is on top.
        child: NavigationBarScope(
          controller: sl<NavigationBarController>(),
          child: MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeManager.lightTheme,
            initialRoute: Routes.splash,
            onGenerateRoute: AppRouter.getRoute,
            navigatorKey: myGlobalNavigatorKey,
            scaffoldMessengerKey: _messengerKey,
            navigatorObservers: <NavigatorObserver>[
              ...AnalyticsScope.navigatorObservers,
              sl<NavigationBarController>().observer,
            ],
          ),
        ),
      ),
    ),
  );
}
