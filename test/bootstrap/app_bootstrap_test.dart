import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
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
    bannerAdUnitId: 'banner-unit',
    interstitialAdUnitId: 'interstitial-unit',
  );

  group('bootstrapApp composition', () {
    test('starts every enabled module and reports success', () async {
      final harness = _Harness();

      final runtime = await harness.boot(env);

      expect(runtime.isHealthy, isTrue);
      expect(runtime.kit.modules.keys, containsAll(<String>[
        AppModules.deviceIdentity,
        AppModules.consent,
        AppModules.ads,
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

    test('the modules whose features have not migrated stay disabled', () {
      // Enabling one of these while the old code still writes its keys gives
      // two writers and divergent user state, so each waits for its feature.
      expect(AppModules.disabled, containsAll(<String>[
        'app_rating',
        'onboarding',
        'permissions',
        'app_links',
        'notifications.local',
      ]));
    });

    test('remote config and engagement are enabled, not disabled', () {
      // Their features migrated: AdConfig, FirebaseRemoteConfigService,
      // RetentionTracker and UserTargetingManager are gone from lib/, so
      // nothing else writes the keys they now own.
      expect(AppModules.disabled, isNot(contains(AppModules.remoteConfig)));
      expect(AppModules.disabled, isNot(contains(AppModules.engagement)));
    });

    test('a required module failing yields a failed report, not a half app',
        () async {
      final harness = _Harness()..ads.failOnInitialize = true;

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
    test('carries the AdMob test device id forward unchanged', () {
      expect(env.adMob.testDeviceIds,
          contains('5e2d630f-0073-4c73-b2b8-f05738eb5b6f'));
    });

    test('gives the full-screen adapter only full-screen units', () {
      // AdMobAdProvider serves interstitial, rewarded and app-open. Handing it
      // a banner made it fail initialization outright, which took the entire
      // ads module down on device while every unit test passed.
      expect(env.adMob.unitFor(AppPlacements.interstitial)?.adUnitId,
          'interstitial-unit');
      expect(env.adMob.unitFor(AppPlacements.banner), isNull);
      for (final unit in env.adMob.adUnits.values) {
        expect(unit.placement.format, isNot(AdFormat.banner));
      }
    });

    test('carries the banner unit separately, for the inline ad view', () {
      expect(env.bannerAdUnit.adUnitId, 'banner-unit');
      expect(env.bannerAdUnit.placement.format, AdFormat.banner);
    });

    test('reproduces the app PostHog settings rather than kit defaults', () {
      // Parity: the app ships session replay with masking off. Changing that is
      // a product decision, not a migration side effect.
      expect(env.postHog.maskAllTexts, isFalse);
      expect(env.postHog.maskAllImages, isFalse);
      expect(env.postHog.sessionReplayEnabled, isFalse); // isDevelopment: true
    });

    test('disables crash collection in development builds', () {
      expect(env.crash.collectionEnabled, isFalse);
    });

    test('only activates consent debug geography in development', () {
      expect(env.consentDebug.isActive, isTrue);
      const production = AppEnv(
        isDevelopment: false,
        revenueCatAndroidKey: '',
        oneSignalAppId: '',
        postHogApiKey: '',
        feedbackNestApiKey: '',
        bannerAdUnitId: '',
        interstitialAdUnitId: '',
      );
      expect(production.consentDebug.isActive, isFalse);
      expect(production.crash.collectionEnabled, isTrue);
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
      ),
    );
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

  String get moduleId;

  ModuleHealth get health => ModuleHealth(
        moduleId: moduleId,
        state: state,
        observedAt: DateTime.utc(2026),
      );

  Stream<ModuleHealth> get healthChanges => const Stream<ModuleHealth>.empty();

  Future<KitResult<void>> start() async {
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
  @override
  String get providerId => 'fake';
  @override
  String get moduleId => 'consent.fake';
  @override
  ConsentSnapshot get snapshot => ConsentSnapshot(
        state: ConsentState.notRequired,
        observedAt: DateTime.utc(2026),
      );
  @override
  Stream<ConsentSnapshot> get snapshotChanges =>
      const Stream<ConsentSnapshot>.empty();
  @override
  Future<KitResult<void>> initialize() => start();
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
  @override
  String get sinkId => 'fake';
  @override
  String get moduleId => 'analytics.fake';
  @override
  Future<KitResult<void>> initialize() => start();
  @override
  Future<KitResult<void>> dispose() => stop();
  @override
  Future<KitResult<void>> track(AnalyticsEvent event) async =>
      const KitSuccess<void>(null);
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
