import 'package:flutter/material.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/permissions/presentation/screens/status_folder_permission_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/statuses/presentation/screens/media_viewer_screen.dart';
import 'routes.dart';
import 'unknown_route_screen.dart';

export 'routes.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> getRoute(RouteSettings settings) {
    final child = switch (settings.name) {
      Routes.splash => const SplashScreen(),
      Routes.onboarding => const OnboardingScreen(),
      Routes.home => const HomeScreen(),
      Routes.settings => const SettingsScreen(),
      Routes.statusFolderPermission => StatusFolderPermissionScreen(
        isBusinessMode: settings.arguments! as bool,
      ),
      Routes.mediaViewer => MediaViewerScreen(
        arguments: settings.arguments! as MediaViewerArguments,
      ),
      _ => const UnknownRouteScreen(),
    };
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}
