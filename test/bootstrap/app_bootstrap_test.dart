import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_app_links/genrevibes_app_links.dart';
import 'package:genrevibes_app_rating/genrevibes_app_rating.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';
import 'package:storysaver/bootstrap/app_bootstrap.dart';
import 'package:storysaver/bootstrap/app_env.dart';

void main() {
  const env = AppEnv(
    isDevelopment: true,
    revenueCatAndroidKey: 'rc-key',
    oneSignalAppId: 'os-id',
    postHogApiKey: 'ph-key',
    feedbackNestApiKey: 'fn-key',
    appodealAndroidAppKey: 'appodeal-key',
  );

  group('bootstrapApp composition', () {
    test('starts every enabled module and reports success', () async {
      final harness = _Harness();

      final runtime = await harness.boot(env);

      expect(runtime.isHealthy, isTrue);
      expect(runtime.kit.modules.keys, containsAll(<String>[
        AppModules.deviceIdentity,
        AppModules.analytics,
        AppModules.iap,
        AppModules.push,
        AppModules.feedback,
      ]));
      for (final module in runtime.kit.modules.values) {
        expect(module.health.state, ModuleState.ready, reason: module.moduleId);
      }
    });

    test('never constructs a disabled module', () async {
      final harness = _Harness();

      final runtime = await harness.boot(env);

      for (final moduleId in AppModules.disabled) {
        expect(runtime.kit.modules.containsKey(moduleId), isFalse,
            reason: moduleId);
      }
    });

    test('every capability has migrated, so nothing stays disabled', () {
      // A module was disabled while a hand-rolled service still owned its
      // storage keys, because two writers on one key diverge. Each entry left
      // here as the migration ran; the list is now empty, and adding one back
      // means a legacy writer came back with it.
      expect(AppModules.disabled, isEmpty);
    });

    test('the migrated capabilities are constructed and started', () async {
      final runtime = await _Harness().boot(env);

      expect(runtime.kit.modules.keys, containsAll(<String>[
        AppModules.appLinks,
        AppModules.appRating,
        AppModules.localNotifications,
        AppModules.onboarding,
      ]));
      expect(
        runtime.kit.modules[AppModules.onboarding]?.health.state,
        ModuleState.ready,
      );
    });

    test('onboarding adopts the key the old service wrote', () async {
      // Without the legacy mapping every user who already finished onboarding
      // is shown it again on the release that adopts the module.
      final harness = _Harness();
      await harness.store.setBool('has_seen_onboarding', true);

      final runtime = await harness.boot(env);

      expect(runtime.onboarding.isCompleted, isTrue,
          reason: 'a returning user must not be onboarded twice');
    });

    test('remote config and engagement are enabled, not disabled', () {
      // Their features migrated: AdConfig, FirebaseRemoteConfigService,
      // RetentionTracker and UserTargetingManager are gone from lib/, so
      // nothing else writes the keys they now own.
      expect(AppModules.disabled, isNot(contains(AppModules.remoteConfig)));
      expect(AppModules.disabled, isNot(contains(AppModules.engagement)));
      expect(AppModules.disabled, isNot(contains(AppModules.permissions)));
    });

    test('a required module failing yields a failed report, not a half app',
        () async {
      final harness = _Harness()..iap.failOnInitialize = true;

      final runtime = await harness.boot(env);

      expect(runtime.isHealthy, isFalse);
      expect(
        runtime.initialization.fold(
          onSuccess: (_) => null,
          onFailure: (error) => error.code,
        ),
        isNotNull,
      );
    });

    test('an optional module failing leaves the app healthy', () async {
      // Analytics is registered isRequired: false, so losing PostHog or
      // Firebase must not stop the app from starting.
      final harness = _Harness()..analyticsSink.failOnInitialize = true;

      final runtime = await harness.boot(env);

      expect(runtime.isHealthy, isTrue);
    });
  });

  group('analytics is not gated on ad consent', () {
    test('events reach the sinks even when UMP has not resolved', () async {
      // UMP governs ad personalization. Product analytics is a core function of
      // the application and is not an ad-network decision.
      //
      // This used to be wired the other way: the consent snapshot set the
      // pipeline's consent, so an unresolved decision meant no product
      // analytics at all. It was wrong in both directions, because
      // ConsentStatus.obtained only reports that the flow completed — Google
      // leaves personalized versus non-personalized undefined at that level —
      // so the boolean said "allowed" for a user who had declined and "denied"
      // for one who had merely not been asked.
      final harness = _Harness()
        ..consent.consentState = ConsentState.consentRequired;

      final runtime = await harness.boot(env);
      await runtime.analytics.track(const AnalyticsEvent(name: 'probe'));

      expect(harness.analyticsSink.tracked.map((event) => event.name),
          contains('probe'));
    });

    test('a refused decision does not silence analytics either', () async {
      final harness = _Harness()..consent.consentState = ConsentState.unknown;

      final runtime = await harness.boot(env);
      await runtime.analytics.track(const AnalyticsEvent(name: 'probe'));

      expect(harness.analyticsSink.tracked, isNotEmpty);
    });
  });

  group('consent does not sit on the startup path', () {
    test('boot returns without waiting for consent or ads', () async {
      // Consent may present a form and wait for a person to dismiss it. On the
      // startup chain that held back eight modules and the first frame with
      // them, measured at two to four seconds on device even with no form.
      //
      // Asserted by holding consent open forever rather than by inspecting
      // which modules have appeared yet: `_startDeferred` registers a module
      // synchronously before awaiting it, so a "not registered yet" check
      // passes or fails on how many microtasks happened to elapse, and any
      // unrelated `await` added to bootstrap silently flips it.
      final harness = _Harness()..consent.blockInitialization = Completer<void>();

      final runtime = await harness.boot(env).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw StateError('boot waited for consent'),
      );

      expect(runtime.isHealthy, isTrue);
      expect(
        runtime.kit.modules[AppModules.ads]?.health.state,
        isNot(ModuleState.ready),
        reason: 'ads must not be ready before consent resolves',
      );

      harness.consent.blockInitialization!.complete();
      await runtime.kit.deferredStartupComplete;

      expect(runtime.kit.modules[AppModules.consent], isNotNull);
      expect(runtime.kit.modules[AppModules.ads], isNotNull);
    });

    test('they start afterwards, consent before ads', () async {
      final harness = _Harness();

      final runtime = await harness.boot(env);
      // Let the deferred chain run.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(runtime.kit.modules.containsKey(AppModules.consent), isTrue);
      expect(runtime.kit.modules.containsKey(AppModules.ads), isTrue);
      expect(harness.consent.initializedAt, isNotNull);
      expect(harness.ads.initializedAt, isNotNull);
      expect(
        harness.consent.initializedAt!.isAfter(harness.ads.initializedAt!),
        isFalse,
        reason: 'Google requires consent gathered before an ad is requested',
      );
    });

    test('a consent failure cannot fail the application', () async {
      final harness = _Harness()..consent.failOnInitialize = true;

      final runtime = await harness.boot(env);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(runtime.isHealthy, isTrue);
    });
  });

  group('identity and crash', () {
    test('names the crash reporter with the stable install id', () async {
      final harness = _Harness();

      final runtime = await harness.boot(env);

      final installId = runtime.identity.current!.installId;
      expect(installId, isNotEmpty);
      expect(harness.crashReporter.userIdentifier, installId);
    });

    test('adopts a legacy device_uuid instead of minting a new id', () async {
      final harness = _Harness()
        ..store = MemoryKeyValueStore(
          initialValues: <String, Object?>{'device_uuid': 'legacy-install'},
        );

      final runtime = await harness.boot(env);

      expect(runtime.identity.current!.installId, 'legacy-install');
    });

    test('does not prompt for tracking at launch', () async {
      // An out-of-context ATT prompt at launch is an App Store rejection.
      final harness = _Harness();

      await harness.boot(env);

      expect(harness.advertising.prompted, isFalse);
    });
  });

  group('premium bridge', () {
    test('an entitlement change flips the ad policy', () async {
      final harness = _Harness();
      final runtime = await harness.boot(env);
      expect(runtime.adPolicy.isPremium, isFalse);

      harness.iap.emitEntitlement(active: true);
      await Future<void>.delayed(Duration.zero);

      expect(runtime.adPolicy.isPremium, isTrue);
    });

    test('losing the entitlement restores ads', () async {
      final harness = _Harness();
      final runtime = await harness.boot(env);
      harness.iap.emitEntitlement(active: true);
      await Future<void>.delayed(Duration.zero);

      harness.iap.emitEntitlement(active: false);
      await Future<void>.delayed(Duration.zero);

      expect(runtime.adPolicy.isPremium, isFalse);
    });
  });

  group('AppEnv', () {
    test('configures Appodeal for every placement, under default', () {
      // Appodeal has no ad-unit IDs: the app key selects the app, and each
      // placement only picks dashboard rules. flutter_test reports Android.
      expect(env.appodeal.appKey, 'appodeal-key');
      expect(env.appodeal.placementFor(AppPlacements.banner)?.name, 'default');
      expect(
        env.appodeal.placementFor(AppPlacements.interstitial)?.name,
        'default',
      );
      expect(
        env.appodeal.placementFor(AppPlacements.onboardingNative)?.name,
        'default',
      );
      expect(
        env.appodeal.formats,
        <AdFormat>{AdFormat.banner, AdFormat.interstitial, AdFormat.native},
      );
    });

    test('gives development builds developer access, with the default passcode',
        () {
      // No developer_passcode in this env, so the portfolio default applies.
      expect(env.developerAccess.isDevelopmentBuild, isTrue);
      expect(env.developerAccess.matchesPasscode('1234567'), isTrue);
    });

    test('leaves session replay to the controller, in its safe state', () {
      // The environment no longer decides any of these. SessionReplayController
      // resolves recording and masking together from the rollout, and
      // withSessionReplay applies all three before the SDK is configured. What
      // is here is only what would ship if that never ran.
      expect(env.postHog.sessionReplayEnabled, isFalse);
      // Masking off, as it was pre-kit: a masked replay cannot show where a
      // user got stuck. The remote keys turn it on without a release.
      expect(env.postHog.maskAllTexts, isFalse);
      expect(env.postHog.maskAllImages, isFalse);
    });

    test('does not let the analytics SDK show surveys of its own', () {
      expect(env.postHog.surveys, isFalse);
      expect(env.postHog.toSdkConfiguration().surveys, isFalse);
    });

    test('disables crash collection in development builds', () {
      expect(env.crash.collectionEnabled, isFalse);
    });

    test('collects crashes in release builds', () {
      const production = AppEnv(
        isDevelopment: false,
        revenueCatAndroidKey: '',
        oneSignalAppId: '',
        postHogApiKey: '',
        feedbackNestApiKey: '',
        appodealAndroidAppKey: '',
      );
      expect(production.crash.collectionEnabled, isTrue);
    });

    test('keeps development builds out of the replay rollout by default', () {
      // A development build that records costs the same and fills the same
      // dashboards as a real user, for footage of a test handset. It seeds
      // itself off; the dart-define seeds it on for a deliberate check.
      expect(env.sessionReplayBuildOverride, SessionReplayOverride.forceOff);

      const forced = AppEnv(
        isDevelopment: true,
        revenueCatAndroidKey: '',
        oneSignalAppId: '',
        postHogApiKey: '',
        feedbackNestApiKey: '',
        appodealAndroidAppKey: '',
        forceSessionReplay: true,
      );
      expect(forced.sessionReplayBuildOverride, SessionReplayOverride.forceOn);
    });

    test('release builds seed nothing and follow the rollout', () {
      const production = AppEnv(
        isDevelopment: false,
        revenueCatAndroidKey: '',
        oneSignalAppId: '',
        postHogApiKey: '',
        feedbackNestApiKey: '',
        appodealAndroidAppKey: '',
        // Ignored in release: the rollout is the only thing that decides.
        forceSessionReplay: true,
      );
      expect(production.sessionReplayBuildOverride, isNull);
    });
  });
}

/// Builds a runtime with every vendor boundary faked.
final class _Harness {
  KeyValueStore store = MemoryKeyValueStore();
  final _FakeCrashReporter crashReporter = _FakeCrashReporter();
  final _FakeAdvertising advertising = _FakeAdvertising();
  final _FakeConsent consent = _FakeConsent();
  final _FakeSink analyticsSink = _FakeSink();
  final _FakeAds ads = _FakeAds();
  final _FakeIap iap = _FakeIap();
  final _FakePush push = _FakePush();
  final _FakeFeedback feedback = _FakeFeedback();
  final _FakeRemoteConfig remoteConfig = _FakeRemoteConfig();
  final _FakeSessionReplayRecorder sessionReplayRecorder =
      _FakeSessionReplayRecorder();
  final _FakeLinkOpener linkOpener = _FakeLinkOpener();
  final _FakeStoreReview storeReview = _FakeStoreReview();
  final _FakeLocalNotifications localNotifications = _FakeLocalNotifications();

  Future<dynamic> boot(AppEnv env) {
    return bootstrapApp(
      env,
      crash: CrashCoordinator(reporter: crashReporter, config: env.crash),
      dependencies: BootstrapDependencies(
        store: store,
        advertising: advertising,
        vendor: const NoVendorIdSource(),
        consent: consent,
        analyticsSinks: <AnalyticsSink>[analyticsSink],
        ads: ads,
        iap: iap,
        push: push,
        feedback: feedback,
        remoteConfig: remoteConfig,
        sessionReplayRecorder: sessionReplayRecorder,
        linkOpener: linkOpener,
        storeReview: storeReview,
        localNotifications: localNotifications,
      ),
    );
  }
}

/// Stands in for the PostHog replay controls, which need a method channel.
final class _FakeSessionReplayRecorder implements SessionReplayRecorder {
  bool recording = false;

  @override
  String get providerId => 'fake';

  @override
  Future<KitResult<bool>> isRecording() async => KitSuccess<bool>(recording);

  @override
  Future<KitResult<void>> startRecording() async {
    recording = true;
    return const KitSuccess<void>(null);
  }

  @override
  Future<KitResult<void>> stopRecording() async {
    recording = false;
    return const KitSuccess<void>(null);
  }
}

/// Stands in for the Firebase provider.
///
/// The real one reads `FirebaseRemoteConfig.instance` in its constructor, so
/// merely composing it needs an initialized Firebase app.
final class _FakeRemoteConfig with _FakeModule implements RemoteConfigProvider {
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'remote_config.fake';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  RemoteConfigProviderSnapshot get current => RemoteConfigProviderSnapshot(
        values: const <String, Object?>{},
        origin: RemoteConfigValueOrigin.defaultValue,
        observedAt: DateTime.utc(2026),
      );
  @override
  Future<KitResult<RemoteConfigProviderSnapshot>> refresh() async =>
      KitSuccess<RemoteConfigProviderSnapshot>(current);
}

mixin _FakeModule on Object {
  bool failOnInitialize = false;
  ModuleState state = ModuleState.idle;

  /// When start() ran, so a test can assert deferred ordering.
  DateTime? initializedAt;

  String get moduleId;

  ModuleHealth get health => ModuleHealth(
        moduleId: moduleId,
        state: state,
        observedAt: DateTime.utc(2026),
      );

  Stream<ModuleHealth> get healthChanges => const Stream<ModuleHealth>.empty();

  Future<KitResult<void>> start() async {
    initializedAt = DateTime.now();
    if (failOnInitialize) {
      state = ModuleState.failed;
      return const KitFailure<void>(
        KitError(code: KitErrorCode.provider, message: 'fake failure'),
      );
    }
    state = ModuleState.ready;
    return const KitSuccess<void>(null);
  }

  Future<KitResult<void>> stop() async {
    state = ModuleState.disposed;
    return const KitSuccess<void>(null);
  }
}

final class _FakeCrashReporter with _FakeModule implements CrashReporter {
  String? userIdentifier;

  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'crash.fake';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<void>> setCollectionEnabled(bool enabled) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> setUserIdentifier(String identifier) async {
    userIdentifier = identifier;
    return const KitSuccess<void>(null);
  }

  @override
  Future<KitResult<void>> setCustomKey(String key, Object value) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> record(CrashReport report) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> log(String message) async =>
      const KitSuccess<void>(null);
}

final class _FakeAdvertising implements AdvertisingIdSource {
  bool prompted = false;

  @override
  Future<TrackingAuthorization> authorization() async =>
      TrackingAuthorization.notDetermined;
  @override
  Future<TrackingAuthorization> requestAuthorization() async {
    prompted = true;
    return TrackingAuthorization.authorized;
  }

  @override
  Future<String?> advertisingId() async => null;
}

final class _FakeConsent with _FakeModule implements ConsentProvider {
  /// What UMP would report. Settable so a test can stand in an unresolved or
  /// refused consent decision. Named apart from the module's own `state`.
  ConsentState consentState = ConsentState.notRequired;

  /// Completes `initialize` only when a test says so, standing in for a consent
  /// form sitting open in front of a person.
  Completer<void>? blockInitialization;

  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'consent.fake';
  @override
  ConsentSnapshot get snapshot => ConsentSnapshot(
        state: consentState,
        observedAt: DateTime.utc(2026),
      );
  @override
  Stream<ConsentSnapshot> get snapshotChanges =>
      const Stream<ConsentSnapshot>.empty();
  @override
  Future<KitResult<void>> initialize() async {
    await blockInitialization?.future;
    return start();
  }
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<ConsentSnapshot>> requestConsent() async =>
      KitSuccess<ConsentSnapshot>(snapshot);
  @override
  Future<KitResult<void>> showPrivacyOptions() async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> reset() async => const KitSuccess<void>(null);
}

final class _FakeSink with _FakeModule implements AnalyticsSink {
  /// Events that actually reached this sink.
  final List<AnalyticsEvent> tracked = <AnalyticsEvent>[];

  @override
  String get sinkId => 'fake';
  @override
  String get moduleId => 'analytics.fake';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<void>> track(AnalyticsEvent event) async {
    tracked.add(event);
    return const KitSuccess<void>(null);
  }
  @override
  Future<KitResult<void>> identify(AnalyticsUser user) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> resetIdentity() async => const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> setCollectionEnabled(bool enabled) async =>
      const KitSuccess<void>(null);

  @override
  Future<KitResult<void>> setUserProperties(
    Map<String, Object?> properties,
  ) async =>
      const KitSuccess<void>(null);

  @override
  Future<KitResult<void>> flush() async => const KitSuccess<void>(null);
}

final class _FakeAds with _FakeModule implements AdProvider {
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'ads';
  @override
  Set<AdFormat> get supportedFormats => AdFormat.values.toSet();
  @override
  Stream<AdEvent> get events => const Stream<AdEvent>.empty();
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<void>> load(AdPlacement placement) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<AdShowResult>> show(AdPlacement placement) async =>
      const KitFailure<AdShowResult>(
        KitError(code: KitErrorCode.unavailable, message: 'fake'),
      );
  @override
  bool isReady(AdPlacement placement) => false;

  @override
  Future<KitResult<void>> discard(AdPlacement placement) async =>
      const KitSuccess<void>(null);
}

final class _FakeIap with _FakeModule implements IapProvider {
  final StreamController<EntitlementSnapshot> _entitlements =
      StreamController<EntitlementSnapshot>.broadcast();

  void emitEntitlement({required bool active}) {
    _entitlements.add(
      EntitlementSnapshot(
        entitlements: <Entitlement>[
          if (active)
            Entitlement(
              id: 'Pro',
              productId: 'pro_monthly',
              isActive: true,
              observedAt: DateTime.utc(2026),
            ),
        ],
        observedAt: DateTime.utc(2026),
        provider: 'fake',
      ),
    );
  }

  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'iap';
  @override
  IapCapabilities get capabilities => const IapCapabilities(
        hostedPaywall: false,
        customerCenter: false,
        accountIdentification: false,
        promotionalOffers: false,
      );
  @override
  Stream<EntitlementSnapshot> get entitlementChanges => _entitlements.stream;
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() async {
    await _entitlements.close();
    return stop();
  }

  @override
  Future<KitResult<List<IapProduct>>> getProducts({
    Set<String> productIds = const <String>{},
    String? placementId,
  }) async =>
      const KitSuccess<List<IapProduct>>(<IapProduct>[]);
  @override
  Future<KitResult<PurchaseResult>> purchase(String productId) async =>
      const KitFailure<PurchaseResult>(
        KitError(code: KitErrorCode.unsupported, message: 'fake'),
      );
  @override
  Future<KitResult<PurchaseResult>> presentPaywall({
    String? placementId,
    String? requiredEntitlementId,
  }) async =>
      const KitFailure<PurchaseResult>(
        KitError(code: KitErrorCode.unsupported, message: 'fake'),
      );
  @override
  Future<KitResult<void>> presentCustomerCenter() async =>
      const KitFailure<void>(
        KitError(code: KitErrorCode.unsupported, message: 'fake'),
      );
  @override
  Future<KitResult<EntitlementSnapshot>> restorePurchases() async =>
      _empty();
  @override
  Future<KitResult<EntitlementSnapshot>> getEntitlements({
    bool forceRefresh = false,
  }) async =>
      _empty();
  @override
  Future<KitResult<EntitlementSnapshot>> identify(String appUserId) async =>
      _empty();
  @override
  Future<KitResult<EntitlementSnapshot>> resetIdentity() async => _empty();

  KitResult<EntitlementSnapshot> _empty() => KitSuccess<EntitlementSnapshot>(
        EntitlementSnapshot(
          entitlements: const <Entitlement>[],
          observedAt: DateTime.utc(2026),
          provider: 'fake',
        ),
      );
}

final class _FakePush with _FakeModule implements PushNotificationProvider {
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'notifications.push';
  @override
  Stream<PushEvent> get events => const Stream<PushEvent>.empty();
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<PushSubscriptionState>> getSubscriptionState() async =>
      _state();
  @override
  Future<KitResult<PushSubscriptionState>> requestPermission({
    bool fallbackToSettings = false,
  }) async =>
      _state();
  @override
  Future<KitResult<PushSubscriptionState>> optIn() async => _state();
  @override
  Future<KitResult<PushSubscriptionState>> optOut() async => _state();
  @override
  Future<KitResult<void>> identify(String externalUserId) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> resetIdentity() async => const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> setTags(Map<String, String> tags) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> removeTags(Iterable<String> keys) async =>
      const KitSuccess<void>(null);

  KitResult<PushSubscriptionState> _state() =>
      const KitSuccess<PushSubscriptionState>(
        PushSubscriptionState(
          providerId: 'fake',
          permission: PushPermissionStatus.notDetermined,
          canRequestPermission: true,
          optedIn: false,
        ),
      );
}

final class _FakeFeedback with _FakeModule implements FeedbackProvider {
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'feedback';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<void>> submit(FeedbackSubmission submission) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> submitRatingAndReview({
    required int rating,
    String? review,
  }) async =>
      const KitSuccess<void>(null);
}

final class _FakeLinkOpener with _FakeModule implements LinkOpener {
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'app_links.fake';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<void>> openUrl(Uri uri, {bool external = true}) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> openEmail({
    required String to,
    String? subject,
    String? body,
  }) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> share({
    required String text,
    String? subject,
  }) async =>
      const KitSuccess<void>(null);
}

final class _FakeStoreReview with _FakeModule implements StoreReviewProvider {
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'app_rating.store';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<bool>> isAvailable() async => const KitSuccess<bool>(true);
  @override
  Future<KitResult<void>> requestReview() async => const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> openStoreListing() async =>
      const KitSuccess<void>(null);
}

final class _FakeLocalNotifications
    with _FakeModule
    implements LocalNotificationScheduler {
  @override
  String get moduleId => 'notifications.local';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Stream<LocalNotificationInteraction> get interactions =>
      const Stream<LocalNotificationInteraction>.empty();
  @override
  Future<KitResult<bool>> requestPermission() async =>
      const KitSuccess<bool>(true);
  @override
  Future<KitResult<void>> show(int id, LocalNotificationContent content) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> schedule(LocalNotificationRequest request) async =>
      const KitSuccess<void>(null);
  @override
  Future<KitResult<List<PendingLocalNotification>>> pending() async =>
      const KitSuccess<List<PendingLocalNotification>>(
        <PendingLocalNotification>[],
      );
  @override
  Future<KitResult<void>> cancel(int id) async => const KitSuccess<void>(null);
  @override
  Future<KitResult<void>> cancelAll() async => const KitSuccess<void>(null);
}
