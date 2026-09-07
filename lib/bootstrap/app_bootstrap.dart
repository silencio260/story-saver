import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_analytics_firebase/genrevibes_analytics_firebase.dart';
import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_consent_ump/genrevibes_consent_ump.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_device_identity_platform/genrevibes_device_identity_platform.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_feedbacknest/genrevibes_feedbacknest.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_iap_revenuecat/genrevibes_iap_revenuecat.dart';
import 'package:genrevibes_iap_revenuecat_ui/genrevibes_iap_revenuecat_ui.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_notifications_onesignal/genrevibes_notifications_onesignal.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';
import 'package:genrevibes_storage_shared_preferences/genrevibes_storage_shared_preferences.dart';

import 'app_env.dart';
import 'app_runtime.dart';

/// Module IDs, so registration and lookup cannot drift apart.
abstract final class AppModules {
  /// Crash reporting.
  static const crash = 'crash';

  /// Stable install identity.
  static const deviceIdentity = 'device_identity';

  /// Privacy consent.
  static const consent = 'consent';

  /// Ad provider.
  static const ads = 'ads';

  /// Analytics fan-out.
  static const analytics = 'analytics';

  /// Purchases.
  static const iap = 'iap';

  /// Remote push.
  static const push = 'notifications.push';

  /// Feedback submission.
  static const feedback = 'feedback';

  /// Registered but disabled until their feature migrates.
  static const disabled = <String>[
    'remote_config',
    'engagement',
    'permissions',
    'app_rating',
    'onboarding',
    'app_links',
    'notifications.local',
  ];
}

/// Builds and starts every kit module this app has adopted.
///
/// This is the composition root. It decides *what* exists and *in what order*
/// it starts; it holds no policy of its own.
///
/// Scope note: this stage moves SDK **initialization** into the kit. Feature
/// code still runs against its own repositories, which now work against SDKs
/// the kit configured rather than configuring them a second time. Modules whose
/// feature has not migrated are registered disabled, so no capability starts
/// writing state that the old code still owns.
///
/// [dependencies] exists for tests, which substitute fakes for every vendor
/// boundary. Production passes nothing.
Future<AppRuntime> bootstrapApp(
  AppEnv env, {
  required CrashCoordinator crash,
  BootstrapDependencies dependencies = const BootstrapDependencies(),
  Duration moduleTimeout = const Duration(seconds: 10),
}) async {
  final store = MigratingKeyValueStore(
    delegate: dependencies.store ?? SharedPreferencesKeyValueStore(),
    // Only the enabled modules' legacy keys. Rating, onboarding and engagement
    // keys are adopted when those modules are enabled, because adopting a key
    // while the old code still writes it gives two writers and divergent state.
    legacyKeys: DeviceIdentityKeys.legacyKeys,
    removeLegacyOnRead: false,
  );

  final identity = DeviceIdentityResolver(
    store: store,
    advertising:
        dependencies.advertising ?? const AttAdvertisingIdSource(),
    vendor: dependencies.vendor ?? const DeviceInfoVendorIdSource(),
  );
  final consentProvider = dependencies.consent ??
      UmpConsentProvider(debugConfig: env.consentDebug);
  final consent = ConsentGate(provider: consentProvider);
  final analytics = AnalyticsPipeline(
    sinks: dependencies.analyticsSinks ??
        <AnalyticsSink>[
          FirebaseAnalyticsSink(),
          PostHogAnalyticsSink(configuration: env.postHog),
        ],
  );
  final adPolicy = AdPolicyController(
    placements: <String, AdPlacementPolicy>{
      for (final placement in AppPlacements.all)
        placement.id: const AdPlacementPolicy(),
    },
  );
  final ads = dependencies.ads ?? AdMobAdProvider(configuration: env.adMob);
  final iap = dependencies.iap ??
      RevenueCatIapProvider(
        configuration: env.revenueCat,
        uiPresenter: const RevenueCatUiAdapter(),
      );
  final push = dependencies.push ??
      OneSignalPushProvider(configuration: env.oneSignal);
  final feedback = dependencies.feedback ??
      FeedbackNestFeedbackProvider(configuration: env.feedbackNest);

  final logger = const BootstrapLogger();

  final kit = GenRevibesStarterKit(
    logger: logger,
    // No vendor callback may hold the first frame hostage. Anything slower
    // than this is a fault, not slowness, and is reported as one.
    moduleTimeout: moduleTimeout,
    modules: <StarterModuleRegistration>[
      // Order is dependency order. Crash first so a later failure is reported;
      // identity next so it can name the user; consent before anything that
      // personalizes.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.crash,
        create: () => crash,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.deviceIdentity,
        create: () => identity,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.consent,
        create: () => consent,
        isRequired: false,
      ),
      // Owns MobileAds.initialize(), which the deleted consent service used to
      // call. Required: without it no ad ever loads.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.ads,
        create: () => ads,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.analytics,
        create: () => analytics,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.iap,
        create: () => iap,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.push,
        create: () => push,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.feedback,
        create: () => feedback,
        isRequired: false,
      ),
      for (final moduleId in AppModules.disabled)
        StarterModuleRegistration.disabled(moduleId: moduleId),
    ],
  );

  final initialization = await kit.initialize();

  // Consent gates analytics. The pipeline starts disabled and its sinks are
  // never initialized until consent is granted, so without this wiring
  // analytics silently collects nothing. Subscribing as well as reading once
  // means a later change through the privacy-options form takes effect
  // immediately.
  void applyConsent(ConsentSnapshot snapshot) {
    unawaited(
      analytics.setConsent(
        snapshot.allowsPersonalizedWork
            ? AnalyticsConsent.granted
            : AnalyticsConsent.denied,
      ),
    );
  }

  // Bounded for the same reason module initialization is: a UMP form that
  // never calls back would otherwise suspend startup here, after the kit has
  // already reported itself healthy.
  applyConsent(
    await consent.ready.timeout(
      moduleTimeout,
      onTimeout: () {
        logger.log(
          KitLogLevel.warning,
          'Consent did not resolve in time; starting without personalization.',
          moduleId: AppModules.consent,
        );
        return ConsentSnapshot(
          state: ConsentState.unknown,
          observedAt: DateTime.now(),
        );
      },
    ),
  );
  consentProvider.snapshotChanges.listen(applyConsent);

  // Name the user on crash reports. Tracking is deliberately not prompted here:
  // an out-of-context ATT prompt at launch is an App Store rejection.
  final resolved = await identity.resolve().timeout(
        moduleTimeout,
        onTimeout: () => const KitFailure<DeviceIdentity>(
          KitError(
            code: KitErrorCode.timeout,
            message: 'Device identity did not resolve in time.',
          ),
        ),
      );
  await resolved.fold(
    onSuccess: (value) => crash.identify(value.installId),
    onFailure: (_) async => const KitSuccess<void>(null),
  );

  // The single premium source of truth for the kit's ad policy. The two
  // existing bridges (my_app.dart's BlocListener and
  // BannerAdWidget._syncSubscription) stay until the ads migration, because
  // AdsBloc still reads SubscriptionManager rather than this controller.
  iap.entitlementChanges.listen(
    (snapshot) => adPolicy.setPremium(
      snapshot.activeEntitlementIds.isNotEmpty,
    ),
  );

  return AppRuntime(
    kit: kit,
    initialization: initialization,
    store: store,
    crash: crash,
    identity: identity,
    consent: consent,
    analytics: analytics,
    adPolicy: adPolicy,
    ads: ads,
    iap: iap,
    push: push,
    feedback: feedback,
  );
}

/// Vendor boundaries a test can replace.
///
/// Every field is null in production. Tests supply fakes so composition,
/// ordering and the premium bridge are verified without a device.
final class BootstrapDependencies {
  /// Creates dependencies. All null means "use the real implementations".
  const BootstrapDependencies({
    this.store,
    this.advertising,
    this.vendor,
    this.consent,
    this.analyticsSinks,
    this.ads,
    this.iap,
    this.push,
    this.feedback,
  });

  /// Backing key-value store.
  final KeyValueStore? store;

  /// Advertising identifier source.
  final AdvertisingIdSource? advertising;

  /// Vendor identifier source.
  final VendorIdSource? vendor;

  /// Consent provider.
  final ConsentProvider? consent;

  /// Analytics sinks.
  final List<AnalyticsSink>? analyticsSinks;

  /// Ad provider.
  final AdProvider? ads;

  /// IAP provider.
  final IapProvider? iap;

  /// Push provider.
  final PushNotificationProvider? push;

  /// Feedback provider.
  final FeedbackProvider? feedback;
}

/// Routes starter-kit lifecycle logs to the console during development.
///
/// The kit defaults to a no-op logger, and crash collection is off in debug, so
/// without this a module that fails or times out at startup leaves no trace
/// anywhere. Release builds stay silent: the crash reporter is the sink there.
final class BootstrapLogger implements KitLogger {
  /// Creates a logger.
  const BootstrapLogger();

  @override
  void log(
    KitLogLevel level,
    String message, {
    String? moduleId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!kDebugMode) return;
    final where = moduleId == null ? '' : ' [$moduleId]';
    debugPrint('[genrevibes:${level.name}]$where $message'
        '${error == null ? '' : ' error=$error'}');
  }
}
