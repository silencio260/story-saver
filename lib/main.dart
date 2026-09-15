import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash_crashlytics/genrevibes_crash_crashlytics.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'bloc_observer.dart';
import 'bootstrap/app_bootstrap.dart';
import 'bootstrap/app_env.dart';
import 'bootstrap/app_runtime.dart';
import 'config/theme_manager.dart';
import 'features/monetization/data/services/subscription_service.dart';
import 'bootstrap/runtime_registrar.dart';
import 'container_injector.dart';
import 'features/analytics/data/services/analytics_service.dart';
import 'features/saved_media/data/services/auto_save_service.dart';
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

CrashCoordinator? _activeCrash;

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(_StartupApp(env: AppEnv.fromDefines()));
    },
    (error, stack) {
      debugPrint('Uncaught application error: ${error.runtimeType}');
      unawaited(
        _activeCrash?.report(
          CrashReport(
            error: error,
            stackTrace: stack,
            fatal: true,
            source: CrashSource.zone,
          ),
        ),
      );
    },
  );
}

/// The first frame always renders, even when Firebase or a plugin is offline.
class _StartupApp extends StatefulWidget {
  const _StartupApp({required this.env});
  final AppEnv env;
  @override
  State<_StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<_StartupApp> {
  AppRuntime? _runtime;
  KitResourceScope? _resources;
  bool _starting = false;
  String? _failure;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_starting || !mounted) return;
    setState(() {
      _starting = true;
      _failure = null;
    });
    final attempt = ++_attempt;
    final resources = KitResourceScope();
    _resources = resources;
    final crash = CrashCoordinator(
      reporter: CrashlyticsReporter(),
      config: widget.env.crash,
    );
    _activeCrash = crash;
    resources.addModule(crash);
    try {
      final runtime = await _prepare(
        resources,
        crash,
      ).timeout(const Duration(seconds: 60));
      resources.ensureActive();
      if (!mounted || attempt != _attempt) {
        await resources.dispose();
        return;
      }
      if (runtime.initialization.isFailure) {
        throw StateError('A service needed to start the app is unavailable.');
      }
      registerRuntime(runtime);
      SubscriptionManager().refreshAccessPolicy();
      initAppDependencies();
      AutoSaveService.bindNotifications(runtime.localNotifications);
      resources.add(
        () => AutoSaveService.releaseNotifications(runtime.localNotifications),
      );
      unawaited(
        _startupStep('auto_save', AutoSaveService.checkAndResumeDevMode),
      );
      final hooks = CrashHooks.install(crash);
      resources.add(hooks.restore);
      final previousObserver = Bloc.observer;
      Bloc.observer = AppBlocObserver(crash);
      resources.add(() => Bloc.observer = previousObserver);
      setState(() {
        _runtime = runtime;
        _starting = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !resources.isClosed) {
          unawaited(runtime.kit.startDeferred());
          unawaited(runtime.pushAnalytics.refresh(reason: 'startup'));
          unawaited(runtime.dailyReminders.sync());
          unawaited(AnalyticsService.drainPending());
        }
      });
    } on Object catch (error, stack) {
      // Do not expose provider errors/keys on the recovery screen.
      debugPrint('Startup attempt failed: ${error.runtimeType}');
      unawaited(
        crash.report(
          CrashReport(
            error: error,
            stackTrace: stack,
            reason: 'Application startup',
            source: CrashSource.flutter,
          ),
        ),
      );
      await resources.dispose();
      if (identical(_activeCrash, crash)) _activeCrash = null;
      await sl.reset();
      SubscriptionManager().reset();
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _starting = false;
        _failure =
            error is TimeoutException
                ? 'Starting the app took too long. Please try again.'
                : 'The app could not start. Check your connection and try again.';
      });
    }
  }

  Future<AppRuntime> _prepare(
    KitResourceScope resources,
    CrashCoordinator crash,
  ) async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    ).timeout(const Duration(seconds: 3));
    resources.ensureActive();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    await Firebase.initializeApp().timeout(const Duration(seconds: 20));
    resources.ensureActive();
    final runtime = await bootstrapApp(
      widget.env,
      crash: crash,
      resources: resources,
      autoStartDeferred: false,
    );
    resources.ensureActive();
    await _startupStep('media_store', MediaStore.ensureInitialized);
    resources.ensureActive();
    await _startupStep(
      'workmanager',
      () => Workmanager().initialize(callbackDispatcher),
    );
    resources.ensureActive();
    return runtime;
  }

  @override
  void dispose() {
    _attempt++;
    unawaited(_resources?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_runtime != null) return const MyApp();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeManager.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Story Saver',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                if (_failure == null)
                  const CircularProgressIndicator()
                else ...[
                  Text(_failure!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _starting ? null : _start,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
    debugPrint(
      '[genrevibes] startup step "$name" timed out after '
      '${timeout.inSeconds}s; continuing.',
    );
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
