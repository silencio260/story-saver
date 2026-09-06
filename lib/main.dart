import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_crash_crashlytics/genrevibes_crash_crashlytics.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'bloc_observer.dart';
import 'bootstrap/app_bootstrap.dart';
import 'bootstrap/app_env.dart';
import 'bootstrap/runtime_registrar.dart';
import 'config/firebase_options.dart';
import 'container_injector.dart';
import 'core/usecase/base_usecase.dart';
import 'features/analytics/data/services/user_targeting_manager.dart';
import 'features/analytics/domain/usecases/initialize_analytics_usecase.dart';
import 'features/monetization/data/services/ads/ad_config.dart';
import 'features/saved_media/data/services/auto_save_service.dart';
import 'features/settings/presentation/services/legacy/app_rating_service.dart';
import 'my_app.dart';

/// WorkManager background entry point.
///
/// Moved here from `AppServicesDataSource`, which this stage deletes. It must
/// stay a top-level function annotated `vm:entry-point` so the background
/// isolate can find it.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == AutoSaveService.taskName) {
      await AutoSaveService.initialize();
      await AutoSaveService.executeBackgroundTask();
    }
    return true;
  });
}

void main() {
  final env = AppEnv.fromDefines();
  // Built here rather than inside bootstrapApp because the guarded zone needs
  // it before any app code runs. It is registered as a kit module all the same.
  final crash = CrashCoordinator(
    reporter: CrashlyticsReporter(),
    config: env.crash,
  );

  // Not awaited: runZonedGuarded returns once the zone is established, and the
  // body keeps running inside it.
  CrashHooks.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = const AppBlocObserver();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Firebase is initialized once, here, and awaited. It used to happen three
    // layers down inside AnalyticsService.init(), which deleted any existing
    // app first and swallowed every failure, so a Firebase fault silently
    // disabled analytics, remote config and crash reporting together.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final runtime = await bootstrapApp(env, crash: crash);
    // Installed after the coordinator has started, so a captured error has a
    // live reporter to reach. Zone errors before this point are dropped rather
    // than queued, which is the honest trade for not buffering crashes.
    CrashHooks.install(crash);
    registerRuntime(runtime);
    initAppDependencies();

    // App-owned initialization the kit does not yet cover. AdConfig and
    // UserTargetingManager stay until the remote-config and engagement modules
    // are enabled by their feature migrations.
    await MediaStore.ensureInitialized();
    await Workmanager().initialize(callbackDispatcher);
    await AdConfig.ensureInitialized();
    await UserTargetingManager.startTracking();
    await AutoSaveService.checkAndResumeDevMode();

    // Feature initialization that has not migrated yet.
    await sl<InitializeAnalyticsUseCase>()(NoParams.instance);
    await AdvancedAppRatingService.initialize();

    runApp(const MyApp());
  }, crash);
}
