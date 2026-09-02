import 'package:get_it/get_it.dart';

import 'features/analytics/analytics_injector.dart';
import 'features/app_services/app_services_injector.dart';
import 'features/navigation/navigation_injector.dart';
import 'features/monetization/monetization_injector.dart';
import 'features/onboarding/onboarding_injector.dart';
import 'features/permissions/permissions_injector.dart';
import 'features/saved_media/saved_media_injector.dart';
import 'features/settings/settings_injector.dart';
import 'features/statuses/statuses_injector.dart';

final GetIt sl = GetIt.instance;

void initAppDependencies() {
  initAnalytics();
  initAppServices();
  initPermissions();
  initStatuses();
  initSavedMedia();
  initOnboarding();
  initMonetization();
  initSettings();
  initNavigation();
}
