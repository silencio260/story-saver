import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../features/monetization/presentation/controllers/legacy/ad_suppression_manager.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_analytics_firebase/genrevibes_analytics_firebase.dart';
import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';
import 'package:genrevibes_app_links/genrevibes_app_links.dart';
import 'package:genrevibes_app_links_launcher/genrevibes_app_links_launcher.dart';
import 'package:genrevibes_app_rating/genrevibes_app_rating.dart';
import 'package:genrevibes_app_rating_in_app_review/genrevibes_app_rating_in_app_review.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_consent_ump/genrevibes_consent_ump.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
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
import 'package:genrevibes_notifications_local/genrevibes_notifications_local.dart';
import 'package:genrevibes_onboarding/genrevibes_onboarding.dart';
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

  /// Developer tools and test ads in store builds.
  static const developerAccess = 'developer_access';

  /// Privacy consent.
  static const consent = 'consent';

  /// Ad provider.
  static const ads = 'ads';

  /// Analytics fan-out.
  static const analytics = 'analytics';

  /// Session replay rollout, and the developer override over it.
  static const sessionReplay = 'analytics.session_replay';

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

  /// Share, store, support, privacy and terms links.
  static const appLinks = 'app_links';

  /// Rating eligibility and the store review flow.
  static const appRating = 'app_rating';

  /// Device-local notifications.
  static const localNotifications = 'notifications.local';

  /// Whether the user has finished onboarding.
  static const onboarding = 'onboarding';

  /// Registered but disabled until their feature migrates.
  static const disabled = <String>[];
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
      // Adopted now that RatingCoordinator owns this state and the legacy
      // service no longer writes it. `download_count` was this app's own
      // milestone counter and has no equivalent in RatingKeys.legacyKeys.
      ...RatingKeys.legacyKeys,
      RatingKeys.trigger(_downloadTrigger): 'download_count',
      // Without this every user who already finished onboarding is shown it
      // again on the release that adopts the module.
      ...OnboardingKeys.legacyKeys,
    },
    removeLegacyOnRead: false,
  );

  final identity = DeviceIdentityResolver(
    store: store,
    advertising:
        dependencies.advertising ?? const AttAdvertisingIdSource(),
    vendor: dependencies.vendor ?? const DeviceInfoVendorIdSource(),
  );
  // Who gets the developer tools and test ads. Settled before the ad provider
  // is built, which starts in the mode this decides. A device recognised later
  // — when its identifier resolves, remote config arrives, or the passcode is
  // entered — moves ads over through the listener further down.
  final developerAccess = DeveloperAccessController(
    store: store,
    config: env.developerAccess,
    installMarker: await InstallMarker.read().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    ),
    logger: logger,
  );
  await developerAccess.initialize();
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
  // Started here rather than left to `kit.initialize()` below, which would
  // start it after analytics. Session replay has to be settled before the
  // PostHog SDK is configured — masking is fixed at setup and cannot be moved
  // afterwards — and settling it means reading the rollout first. This costs
  // no network: Firebase's `initialize` only registers defaults and reads the
  // values it activated on a previous run. The registration further down calls
  // this again and the module returns immediately.
  //
  // Bounded all the same. This is the one module now sitting on the critical
  // path, and a provider that never calls back would hold the first frame
  // indefinitely; on timeout the controller resolves against schema defaults,
  // which is the behaviour of an app that has never fetched anything.
  await remoteConfig.initialize().timeout(
        moduleTimeout,
        onTimeout: () => const KitFailure<void>(
          KitError(
            code: KitErrorCode.timeout,
            message: 'Remote config did not initialize in time.',
          ),
        ),
      );

  // Who records, and what their recording shows. The controller draws this
  // install's rollout bucket once and keeps it, so lowering the percentage
  // narrows the recorded group rather than choosing a different one every
  // launch — which is what makes a replay cohort answerable for a retention
  // question.
  final sessionReplay = SessionReplayController(
    store: store,
    policy: SessionReplayRemotePolicyBinder.policyFrom(remoteConfig.current),
    buildOverride: env.sessionReplayBuildOverride,
    logger: logger,
  );
  await sessionReplay.initialize();

  final analytics = AnalyticsPipeline(
    // Granted at construction. Product analytics is a core function of this
    // application, not something an ad-consent dialog decides. See the note
    // further down for why it used to be wired to UMP and why that was wrong.
    initialConsent: AnalyticsConsent.granted,
    sinks: dependencies.analyticsSinks ??
        <AnalyticsSink>[
          FirebaseAnalyticsSink(
            collectionEnabled: env.firebaseAnalyticsCollectionEnabled,
          ),
          PostHogAnalyticsSink(
            configuration: env.postHog.withSessionReplay(sessionReplay.plan),
          ),
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
  final ads = dependencies.ads ??
      AdMobAdProvider(
        configuration: env.adMob,
        testMode: developerAccess.current.servesTestAds,
      );
  final iap = dependencies.iap ??
      RevenueCatIapProvider(
        configuration: env.revenueCat,
        uiPresenter: const RevenueCatUiAdapter(),
      );
  final push = dependencies.push ??
      OneSignalPushProvider(configuration: env.oneSignal);
  final feedback = dependencies.feedback ??
      FeedbackNestFeedbackProvider(configuration: env.feedbackNest);
  final linkOpener = dependencies.linkOpener ?? UrlLauncherLinkOpener();

  // Where this app lives and how to reach us.
  //
  // One value object rather than constants spread through the UI, so a missing
  // store URL or an unset privacy policy is a validation failure here instead
  // of a button that does nothing in a shipped build.
  final appLinksConfig = AppLinksConfig(
    appName: 'Story Saver',
    playStoreUrl: 'https://play.google.com/store/apps/details'
        '?id=com.genrevibes.whatsappstorysaver',
    supportEmail: 'support@genrevibes.com',
    privacyPolicyUrl: env.privacyPolicyUrl,
    termsUrl: env.termsUrl.trim().isEmpty ? null : env.termsUrl,
  );
  final links = AppLinkActions(
    config: appLinksConfig,
    opener: linkOpener,
    isIos: defaultTargetPlatform == TargetPlatform.iOS,
    observer: _AnalyticsAppLinkObserver(analytics),
  );

  final storeReview = dependencies.storeReview ??
      InAppReviewStoreProvider(
        configuration: InAppReviewConfiguration(
          androidStoreUrl: appLinksConfig.playStoreUrl,
          iosStoreUrl: appLinksConfig.appStoreUrl,
        ),
      );

  // Rating policy. The coordinator decides whether to prompt; it never presents
  // UI and never talks to a store, so the rules stay testable against a clock.
  //
  // The suppression hook is wired here rather than inside the module because a
  // rating package must not depend on an ads package. This is the one place
  // that legitimately knows about both.
  // Resolved from the device rather than assumed. The adapter refuses an empty
  // zone on purpose: scheduling against the wrong one shifts every delivery
  // after travel or a DST change, and UTC is wrong for most users.
  final timeZone = await FlutterTimezone.getLocalTimezone()
      .timeout(const Duration(seconds: 2))
      .catchError((Object _) => 'UTC');
  final localNotifications = dependencies.localNotifications ??
      PersistentLocalNotificationScheduler(
        configuration: GenRevibesLocalNotificationsConfiguration(
          // The drawable the auto-save notification already used.
          androidDefaultIcon: 'ic_stat_download',
          timeZoneName: timeZone,
        ),
      );

  final onboarding = OnboardingController(store: store);

  final rating = RatingCoordinator(
    store: store,
    observer: _AnalyticsRatingObserver(analytics),
    suppressionHook: (action) => AdSuppressionManager().withAdsSuppressed<void>(
      reason: 'rating_dialog',
      action: action,
    ),
  );

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
      // Already initialized above, before the ad provider chose its mode.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.developerAccess,
        create: () => developerAccess,
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
      // Already initialized above, before the PostHog SDK was configured from
      // its plan. Registered so it appears in module health beside everything
      // else, and so it is disposed with the rest.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.sessionReplay,
        create: () => sessionReplay,
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
      // Optional: a share sheet that fails is not a reason to refuse to start.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.appLinks,
        create: () => linkOpener,
        isRequired: false,
      ),
      StarterModuleRegistration.enabled(
        moduleId: AppModules.appRating,
        create: () => rating,
        isRequired: false,
      ),
      // Optional: a missed "auto-save finished" notice is not worth a failed
      // launch, and the save itself already happened.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.localNotifications,
        create: () => localNotifications,
        isRequired: false,
      ),
      // Required. The splash screen routes on this, and an unreadable flag
      // resolves to "not onboarded" inside the module rather than here: showing
      // onboarding twice is a far better failure than skipping it for a genuinely
      // new user.
      StarterModuleRegistration.enabled(
        moduleId: AppModules.onboarding,
        create: () => onboarding,
      ),
      // Namespaced under app_rating: the store adapter is the provider half of
      // that capability, not a capability of its own.
      StarterModuleRegistration.enabled(
        moduleId: '${AppModules.appRating}.store',
        create: () => storeReview,
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
    onSuccess: (value) async {
      // Developer devices are listed under a hash of the vendor ID. This is
      // what recognises a listed phone; the ID itself is hashed and dropped.
      developerAccess.setDeviceId(value.vendorId);
      await crash.identify(value.installId);
      // The same identity on analytics, so a crash and the events around it
      // describe one device. The old service sent this as a `unique_device_id`
      // parameter on app_open only; as a user property it applies to every
      // event and can be filtered on.
      await analytics.identify(AnalyticsUser(id: value.installId));
    },
    onFailure: (_) async => const KitSuccess<void>(null),
  );

  // Lets a test device be found in reporting.
  //
  // Firebase excludes debug-enabled devices from standard reports, so a device
  // streaming to DebugView is invisible in the numbers. Turning debug mode off
  // puts it back in the reports, and this property is how it is then picked
  // out or filtered away.
  unawaited(
    analytics.setUserProperties(<String, Object?>{
      'build_type': env.isDevelopment ? 'development' : 'release',
    }),
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

  // Now that the SDK is configured, the controller can move recording without
  // a relaunch: a rollout change, or the switch in the Starter Kit Lab, starts
  // or stops capture in place.
  await sessionReplay.attach(
    dependencies.sessionReplayRecorder ??
        PostHogSessionReplayRecorder(logger: logger),
  );
  final sessionReplayBinder = SessionReplayRemotePolicyBinder.forCoordinator(
    remoteConfig,
    controller: sessionReplay,
    logger: logger,
  );
  await sessionReplayBinder.initialize();

  // The remote developer device list: applied now from what a previous run
  // activated, and again whenever a fetch changes it.
  final developerAccessBinder =
      DeveloperAccessRemotePolicyBinder.forCoordinator(
    remoteConfig,
    controller: developerAccess,
    logger: logger,
  );
  await developerAccessBinder.initialize();

  // Ads follow developer access for the life of the process. A phone that
  // becomes a developer device mid-session drops any live creative it loaded
  // and requests test inventory from then on; the banner widget listens to the
  // same changes. The user property lets a developer's own sessions be
  // filtered out of production numbers.
  void followDeveloperAccess(DeveloperAccess access) {
    // An optional capability on a different interface, so bind it by pattern:
    // `is` cannot narrow an AdProvider to an unrelated type.
    if (ads case final AdTestModeProvider testable) {
      unawaited(testable.setTestMode(access.servesTestAds));
    }
    unawaited(
      analytics.setUserProperties(<String, Object?>{
        'developer_access': access.reason.name,
      }),
    );
  }

  followDeveloperAccess(developerAccess.current);
  developerAccess.changes.listen(followDeveloperAccess);

  // Nothing else fetches. `initialize` only reads what a previous run
  // activated, so without this a rollout percentage set in Firebase would
  // reach a device once and never move again — and a fresh install would never
  // see one at all. Unawaited because none of it is worth a slower first frame:
  // the binders are listening, and whatever arrives is applied when it does.
  unawaited(remoteConfig.refresh());

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
    developerAccess: developerAccess,
    consent: consent,
    analytics: analytics,
    adPolicy: adPolicy,
    ads: ads,
    iap: iap,
    push: push,
    feedback: feedback,
    remoteConfig: remoteConfig,
    sessionReplay: sessionReplay,
    retention: retention,
    permissions: permissions,
    links: links,
    linkOpener: linkOpener,
    rating: rating,
    storeReview: storeReview,
    localNotifications: localNotifications,
    onboarding: onboarding,
    bannerAdUnit: env.bannerAdUnit,
    env: env,
    eventLog: eventLog,
    kitLog: kitLog,
  );
}

/// The app's own rating milestone: a completed download.
const _downloadTrigger = 'download';

/// Sends rating lifecycle events to analytics under the app's own names.
///
/// The kit reports neutral outcomes; this maps them onto the events the
/// dashboards already use, including the separate 4- and 5-star events the old
/// service emitted alongside `rating_submitted`.
final class _AnalyticsRatingObserver implements RatingObserver {
  const _AnalyticsRatingObserver(this._analytics);

  final AnalyticsPipeline _analytics;

  @override
  void onEvaluated(RatingDecision decision) {}

  @override
  void onPrompted() {}

  @override
  void onOutcome(RatingOutcome outcome, {int? rating}) {
    switch (outcome) {
      case RatingOutcome.maybeLater:
        _fire('rating_maybe_later');
      case RatingOutcome.never:
        _fire('rating_never');
      case RatingOutcome.submitted:
        _fire(
          'rating_submitted',
          <String, Object?>{if (rating != null) 'star_count': rating},
        );
        if (rating == 4) _fire('rating_4_stars');
        if (rating == 5) _fire('rating_5_stars');
    }
  }

  void _fire(String name, [Map<String, Object?> properties = const {}]) {
    unawaited(
      _analytics.track(AnalyticsEvent(name: name, properties: properties)),
    );
  }
}

/// Sends link actions to analytics under the app's own event names.
///
/// The kit reports a neutral action — `share`, `store`, `support`, `privacy`,
/// `terms` — and this maps the two the app already measures onto the names its
/// dashboards are built on. Unmapped actions are not invented as new events;
/// an event nobody defined is noise.
final class _AnalyticsAppLinkObserver implements AppLinkObserver {
  const _AnalyticsAppLinkObserver(this._analytics);

  final AnalyticsPipeline _analytics;

  static const _events = <String, String>{
    'share': 'share_app',
    'store': 'goto_app_store_page',
  };

  @override
  void onAction(String action, {required bool succeeded}) {
    if (!succeeded) return;
    final name = _events[action];
    if (name == null) return;
    unawaited(_analytics.track(AnalyticsEvent(name: name)));
  }
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
    this.sessionReplayRecorder,
    this.permissions,
    this.linkOpener,
    this.storeReview,
    this.localNotifications,
  });

  /// Backing key-value store.
  final KeyValueStore? store;

  /// Runtime session-replay control.
  ///
  /// The real one talks to the PostHog plugin over a method channel, which
  /// a test has no binding for.
  final SessionReplayRecorder? sessionReplayRecorder;

  /// URL, email and share opener.
  final LinkOpener? linkOpener;

  /// Store review provider.
  final StoreReviewProvider? storeReview;

  /// Device-local notification scheduler.
  final LocalNotificationScheduler? localNotifications;

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
