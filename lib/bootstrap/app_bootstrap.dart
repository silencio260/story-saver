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
import 'package:genrevibes_devtools/genrevibes_devtools.dart';
import 'package:genrevibes_engagement/genrevibes_engagement.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_feedbacknest/genrevibes_feedbacknest.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_iap_revenuecat/genrevibes_iap_revenuecat.dart';
import 'package:genrevibes_iap_revenuecat_ui/genrevibes_iap_revenuecat_ui.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_notifications_onesignal/genrevibes_notifications_onesignal.dart';
import 'package:genrevibes_permissions/genrevibes_permissions.dart';
import 'package:genrevibes_permissions_handler/genrevibes_permissions_handler.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_config_firebase/genrevibes_remote_config_firebase.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
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

  /// Typed remote configuration.
  static const remoteConfig = 'remote_config';

  /// Retention and targeting.
  static const engagement = 'engagement';

  /// Runtime permissions.
  static const permissions = 'permissions';

  /// Registered but disabled until their feature migrates.
  static const disabled = <String>[
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
  final logger = const BootstrapLogger();

  // Development-only recorders. Firebase's DebugView cannot be enabled from
  // application code — on Android it reads a system property only a shell can
  // set — so an application that wants to watch its own events during
  // development has to keep that record itself. Null in release, so nothing is
  // retained and no history exists to leak.
  final eventLog =
      env.isDevelopment ? RecordingDeliveryObserver() : null;
  final kitLog = env.isDevelopment ? RecordingKitLogger() : null;

  final store = MigratingKeyValueStore(
    delegate: dependencies.store ?? SharedPreferencesKeyValueStore(),
    // Only the enabled modules' legacy keys. Rating, onboarding and engagement
    // keys are adopted when those modules are enabled, because adopting a key
    // while the old code still writes it gives two writers and divergent state.
    legacyKeys: <String, String>{
      ...DeviceIdentityKeys.legacyKeys,
      ...EngagementKeys.legacyKeys,
    },
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
  // Remote configuration is built before analytics, because the pipeline
  // resolves event names through it: a name overridden remotely then reaches
  // every sink and every kit emitter without those packages knowing that
  // remote config exists.
  final remoteConfigSchema = PortfolioRemoteConfigSchema.build();
  final remoteConfig = RemoteConfigCoordinator(
    schema: remoteConfigSchema,
    provider: dependencies.remoteConfig ??
        GenRevibesFirebaseRemoteConfigProvider(schema: remoteConfigSchema),
    logger: logger,
  );
  final analytics = AnalyticsPipeline(
    // Granted at construction. Product analytics is a core function of this
    // application, not something an ad-consent dialog decides. See the note
    // further down for why it used to be wired to UMP and why that was wrong.
    initialConsent: AnalyticsConsent.granted,
    sinks: dependencies.analyticsSinks ??
        <AnalyticsSink>[
          FirebaseAnalyticsSink(),
          PostHogAnalyticsSink(configuration: env.postHog),
        ],
    names: RemoteAnalyticsEventNames.forCoordinator(remoteConfig),
    observer: eventLog,
  );
  // Retention milestones are analytics events, so the tracker reports through
  // the pipeline rather than reaching for a sink of its own.
  final permissions = dependencies.permissions ?? PermissionHandlerProvider();
  final retention = RetentionTracker(
    store: store,
    observer: AnalyticsEngagementObserver(analytics),
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
      // Consent and ads are deferred: they start after the first frame, in
      // this order, and nothing waits for them.
      //
      // Consent may present a form and sit there until someone dismisses it.
      // On the startup chain that held back the eight modules behind it and
      // the first frame with them — measured at two to four seconds on device
      // even when no form appeared. It touches nothing else in this
      // application: its result goes to the ad network and stays there.
      //
      // Ads follow it rather than running alongside, because Google requires
      // consent to be gathered before an ad is requested, and
      // AdMobAdProvider.initialize() owns MobileAds.initialize().
      StarterModuleRegistration.deferred(
        moduleId: AppModules.consent,
        create: () => consent,
      ),
      StarterModuleRegistration.deferred(
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
      // Both optional: a fetch failure falls back to schema defaults, and lost
      // retention history is not worth failing a launch over.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.remoteConfig,
        create: () => remoteConfig,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.engagement,
        create: () => retention,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.permissions,
        create: () => permissions,
        isRequired: false,
      ),
      for (final moduleId in AppModules.disabled)
        StarterModuleRegistration.disabled(moduleId: moduleId),
    ],
  );

  final initialization = await kit.initialize();

  // UMP consent is not wired to analytics, deliberately.
  //
  // It used to be: the snapshot was mapped to the pipeline's consent, so a
  // user UMP had not resolved produced no product analytics at all. That was
  // wrong twice over. UMP governs ad personalization — it is the ad network's
  // consent framework, and its outcome is the ad SDK's business. And
  // `ConsentStatus.obtained` only means the flow completed; Google leaves the
  // personalized/non-personalized distinction undefined at that level, so the
  // boolean it produced said "allowed" for a user who had declined and
  // "denied" for one who simply had not been asked.
  //
  // Product analytics is a core function of this application, not something
  // gated on an ad-consent dialog. The pipeline is constructed already
  // granted, above.
  //
  // Nothing waits on the consent outcome. The flow runs so UMP can store its
  // decision, and the AdMob SDK reads that itself when deciding whether to
  // serve personalized or limited ads — which is exactly what the pre-kit
  // implementation did: run the flow, then initialize ads regardless, "proceed
  // even on error, SDK handles limited ads".

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

  // Remote values retune ad pacing without a release. The binder applies the
  // current snapshot immediately and then follows every change.
  final adPolicyBinder = AdsRemotePolicyBinder(
    current: () => remoteConfig.current,
    changes: remoteConfig.changes,
    policy: adPolicy,
    placements: AppPlacements.all,
    logger: logger,
  );
  await adPolicyBinder.initialize();

  // One app open per launch, which is what emits the D1/D3/D7/D30 milestones.
  // Not awaited for its result: a storage failure degrades the module and must
  // not delay the first frame.
  unawaited(retention.recordAppOpen());

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
    remoteConfig: remoteConfig,
    retention: retention,
    permissions: permissions,
    eventLog: eventLog,
    kitLog: kitLog,
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
    this.remoteConfig,
    this.permissions,
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

  /// Remote configuration provider.
  final RemoteConfigProvider? remoteConfig;

  /// Runtime permission provider.
  final PermissionProvider? permissions;
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
