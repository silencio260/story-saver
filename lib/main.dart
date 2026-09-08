import 'dart:async';

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
import 'container_injector.dart';
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
    Bloc.observer = AppBlocObserver(crash);
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
    //
    // Deliberately without options. Both platforms ship a native configuration
    // file — google-services.json on Android, GoogleService-Info.plist on iOS —
    // so the `[DEFAULT]` app already exists before Dart runs. Passing options
    // makes firebase_core compare them against it and throw `duplicate-app` on
    // any difference, which is what the old `Firebase.app().delete()` call was
    // working around: it discarded the correct native app and rebuilt it from
    // a generated file. There is no generated file now, and the native
    // configuration is the single source of truth per platform.
    //
    // Bounded so a stalled platform call fails loudly instead of leaving the
    // application parked on the launch screen with nothing in the log.
    await Firebase.initializeApp().timeout(const Duration(seconds: 20));

    final runtime = await bootstrapApp(env, crash: crash);
    // Installed after the coordinator has started, so a captured error has a
    // live reporter to reach. Zone errors before this point are dropped rather
    // than queued, which is the honest trade for not buffering crashes.
    CrashHooks.install(crash);
    registerRuntime(runtime);
    initAppDependencies();

    // App-owned initialization the kit does not yet cover.
    //
    // These ran inside `AppServicesRepo.initialize()`'s single try/catch before
    // this migration, which swallowed the first throw and silently skipped
    // every step after it. Each one is isolated here instead, so one failing
    // step neither hides the rest nor stops the application from starting.
    await _startupStep('media_store', MediaStore.ensureInitialized);
    await _startupStep(
      'workmanager',
      () => Workmanager().initialize(callbackDispatcher),
    );
    await _startupStep('auto_save', AutoSaveService.checkAndResumeDevMode);
    await _startupStep('app_rating', AdvancedAppRatingService.initialize);

    runApp(const MyApp());
  }, crash);
}

/// Runs one app-owned startup step without letting it stop the application.
///
/// A step that throws is reported and skipped; a step that never settles is
/// abandoned after [timeout]. Nothing here may hold the first frame: a launch
/// that hangs looks identical to a crash from the outside, and leaves nothing
/// to read afterwards.
Future<void> _startupStep(
  String name,
  Future<void> Function() step, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  try {
    await step().timeout(timeout);
  } on TimeoutException {
    debugPrint('[genrevibes] startup step "$name" timed out after '
        '${timeout.inSeconds}s; continuing.');
  } on Object catch (error, stackTrace) {
    debugPrint('[genrevibes] startup step "$name" failed: $error');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'story saver bootstrap',
        context: ErrorDescription('running startup step "$name"'),
      ),
    );
  }
}
