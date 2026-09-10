import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_feedbacknest/genrevibes_feedbacknest.dart';
import 'package:genrevibes_iap_revenuecat/genrevibes_iap_revenuecat.dart';
import 'package:genrevibes_notifications_onesignal/genrevibes_notifications_onesignal.dart';

/// Logical ad placements this app uses.
///
/// Placement IDs are stable and app-owned; the ad unit behind one may change
/// per platform or from remote configuration without the call sites moving.
abstract final class AppPlacements {
  /// Inline banner shown on the status and saved-media grids.
  static const banner = AdPlacement(id: 'banner', format: AdFormat.banner);

  /// Interstitial shown between full-screen media views.
  static const interstitial =
      AdPlacement(id: 'interstitial', format: AdFormat.interstitial);

  /// Every placement, for policy configuration.
  static const all = <AdPlacement>[banner, interstitial];
}

/// Build-time configuration, read from `--dart-define-from-file`.
///
/// Every key here already exists in the app's `env/*.json`. Nothing is invented
/// and nothing is defaulted to a real credential: an absent key yields an empty
/// string and the module that needs it reports itself unconfigured.
final class AppEnv {
  /// Creates an environment.
  const AppEnv({
    required this.isDevelopment,
    required this.revenueCatAndroidKey,
    required this.oneSignalAppId,
    required this.postHogApiKey,
    required this.feedbackNestApiKey,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    this.forceSessionReplay = false,
    this.forceConsentDebugEea = false,
    this.disableFirebaseAnalyticsInDebug = false,
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.consentTestDeviceIds = '',
  });

  /// Reads the environment from compile-time defines.
  factory AppEnv.fromDefines() {
    return const AppEnv(
      // Matches DevelopmentModeUtils: any of these flags means "not production".
      isDevelopment: kDebugMode ||
          bool.fromEnvironment('development_mode') ||
          bool.fromEnvironment('founders_version') ||
          bool.fromEnvironment('special_version_mode'),
      revenueCatAndroidKey:
          String.fromEnvironment('revenue_cat_api_key_android'),
      oneSignalAppId: String.fromEnvironment('one_signal_app_id'),
      postHogApiKey: String.fromEnvironment('posthog_api_key'),
      feedbackNestApiKey: String.fromEnvironment('feed_back_nest_api_key'),
      bannerAdUnitId: String.fromEnvironment('banner_ad_id'),
      interstitialAdUnitId: String.fromEnvironment('interstitial_ad_id'),
      forceSessionReplay: bool.fromEnvironment('posthog_session_replay'),
      forceConsentDebugEea: bool.fromEnvironment('consent_debug_eea'),
      disableFirebaseAnalyticsInDebug:
          bool.fromEnvironment('disabled_firebase_analytics_in_debug_mode'),
      privacyPolicyUrl: String.fromEnvironment('privacy_policy_url'),
      termsUrl: String.fromEnvironment('terms_url'),
      consentTestDeviceIds:
          String.fromEnvironment('consent_debug_device_ids'),
    );
  }

  /// Whether this build is a development or internal build.
  final bool isDevelopment;

  /// RevenueCat public SDK key for Android.
  final String revenueCatAndroidKey;

  /// OneSignal application ID.
  final String oneSignalAppId;

  /// PostHog project API key.
  final String postHogApiKey;

  /// FeedbackNest project API key.
  final String feedbackNestApiKey;

  /// AdMob banner unit.
  final String bannerAdUnitId;

  /// AdMob interstitial unit.
  final String interstitialAdUnitId;

  /// Turns PostHog session replay on even in a development build.
  ///
  /// Replay is normally release-only, which makes it impossible to check that
  /// it records anything, or that masking behaves, without shipping. Pass
  /// `--dart-define=posthog_session_replay=true` to exercise it locally.
  ///
  /// This is now a *seed* rather than a switch: see
  /// [sessionReplayBuildOverride]. Once a device has been told on or off in the
  /// Starter Kit Lab, that answer wins and this is ignored.
  final bool forceSessionReplay;

  /// Forces UMP into European geography for testing the consent form.
  ///
  /// Off by default. It used to be on in every development build, which meant
  /// UMP reported `consentRequired` on every local run, and because consent
  /// gates the analytics pipeline, **no event reached any sink until the form
  /// was completed**. Analytics appeared to be broken when it was working
  /// exactly as designed. Pass `--dart-define=consent_debug_eea=true` to test
  /// the form deliberately.
  final bool forceConsentDebugEea;

  /// Keeps development traffic out of the Firebase Analytics project.
  ///
  /// Opt-in and development-only: analytics is a core function of the
  /// application, not something to be switched off by accident, so it collects
  /// unless this is explicitly set and the build is a development one. A
  /// release build ignores it entirely.
  ///
  /// Defined as `disabled_firebase_analytics_in_debug_mode` in `env/*.json`.
  final bool disableFirebaseAnalyticsInDebug;

  /// Privacy policy page, required by both stores.
  ///
  /// Empty until configured. `AppLinksConfig.validate()` reports that at
  /// composition, so the gap is visible in module health rather than surfacing
  /// as a dead button in a shipped build.
  final String privacyPolicyUrl;

  /// Terms page, when the app has one. Optional.
  final String termsUrl;

  /// Whether the Firebase sink may collect at all.
  ///
  /// Firebase persists its collection flag on the device, so this has to be
  /// stated on every launch rather than assumed: a build that once turned
  /// collection off leaves it off for every build after it until something
  /// says otherwise.
  bool get firebaseAnalyticsCollectionEnabled =>
      !(isDevelopment && disableFirebaseAnalyticsInDebug);

  /// Hashed device identifiers UMP should treat as test devices.
  ///
  /// Comma separated. Required for [forceConsentDebugEea] to do anything at
  /// all: UMP applies a debug geography only to devices registered here, and
  /// silently ignores it everywhere else. The hash is printed to logcat on
  /// every run — look for "UserMessagingPlatform: Use new
  /// ConsentDebugSettings.Builder().addTestDeviceHashedId(...)".
  final String consentTestDeviceIds;

  /// [consentTestDeviceIds] split into a list.
  List<String> get consentTestDeviceIdList => consentTestDeviceIds
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  /// Crash collection is off in development so local runs do not pollute
  /// production crash-free rates.
  CrashReportingConfig get crash =>
      CrashReportingConfig(collectionEnabled: !isDevelopment);

  /// Consent debug overrides.
  ///
  /// Inactive outside development. The previous implementation hardcoded an
  /// EEA geography in every build, which forced the consent form on users who
  /// should never have seen it.
  ConsentDebugConfig get consentDebug =>
      isDevelopment && forceConsentDebugEea
          ? ConsentDebugConfig(
              geography: ConsentDebugGeography.europeanEconomicArea,
              testDeviceIds: consentTestDeviceIdList,
            )
          : const ConsentDebugConfig();

  /// Whether ads are requested from Google's sample units instead of this
  /// app's own.
  ///
  /// Every development build, whatever its env file says. Requesting a real
  /// unit from a build that is not on the store is invalid traffic under the
  /// AdMob program policies, and it only works at all while the account is in
  /// good standing — a suspended account serves nothing, which left no way to
  /// see an ad locally. Sample units are not tied to any account, so they fill
  /// regardless.
  ///
  /// The manifest follows the same rule: `android/app/build.gradle` names
  /// Google's sample app ID for the same builds.
  bool get useTestAds => isDevelopment;

  /// The banner unit, for `AdMobBannerView`.
  ///
  /// Deliberately not part of [adMob]. `AdMobAdProvider` serves the
  /// full-screen formats only — interstitial, rewarded and app-open — and
  /// rejects a banner unit at initialization, which took the whole ads module
  /// down with it. Inline formats are rendered by the widget in
  /// `genrevibes_ads_admob_ui`, which holds its own unit.
  AdMobAdUnit get bannerAdUnit {
    final unit = AdMobAdUnit(
      placement: AppPlacements.banner,
      adUnitId: bannerAdUnitId,
    );
    return useTestAds ? unit.withTestUnitId() : unit;
  }

  /// AdMob configuration for the full-screen placements this app declares.
  GenRevibesAdMobConfiguration get adMob {
    final configuration = GenRevibesAdMobConfiguration(
      adUnits: <AdMobAdUnit>[
        AdMobAdUnit(
          placement: AppPlacements.interstitial,
          adUnitId: interstitialAdUnitId,
        ),
      ],
      // Carried over verbatim from AppServicesDataSource so test-device
      // behavior does not change with this migration.
      testDeviceIds: const <String>['5e2d630f-0073-4c73-b2b8-f05738eb5b6f'],
    );
    return useTestAds ? configuration.withTestAdUnits() : configuration;
  }

  /// RevenueCat configuration.
  ///
  /// iOS has never had a key configured in this app; leaving it null makes the
  /// provider report itself unconfigured rather than crashing on a null
  /// customer info, which the previous service did.
  RevenueCatConfiguration get revenueCat => RevenueCatConfiguration(
        androidApiKey: Platform.isAndroid ? revenueCatAndroidKey : null,
        logging:
            isDevelopment ? RevenueCatLogging.debug : RevenueCatLogging.errors,
      );

  /// OneSignal configuration.
  GenRevibesOneSignalConfiguration get oneSignal =>
      GenRevibesOneSignalConfiguration(
        appId: oneSignalAppId,
        verboseLogging: isDevelopment,
      );

  /// How this build seeds a device that has never been told either way.
  ///
  /// Replay is a release feature. A development build that records spends the
  /// same money and fills the same dashboards as a real user would, in exchange
  /// for footage of a developer poking at a test handset — so a development
  /// build starts forced off, and `--dart-define=posthog_session_replay=true`
  /// is how it is exercised on purpose.
  ///
  /// Release builds seed nothing and follow the rollout, which is the whole
  /// point of having one.
  ///
  /// A seed only reaches a device with no stored choice. Whatever is chosen in
  /// the Starter Kit Lab wins from then on, including across relaunches.
  SessionReplayOverride? get sessionReplayBuildOverride {
    if (!isDevelopment) return null;
    return forceSessionReplay
        ? SessionReplayOverride.forceOn
        : SessionReplayOverride.forceOff;
  }

  /// PostHog configuration, before session replay is decided.
  ///
  /// These values reproduce `PostHogWrapper.init()` except for replay, which no
  /// longer belongs to the environment at all. `SessionReplayController`
  /// resolves recording and masking together and
  /// `GenRevibesPostHogConfiguration.withSessionReplay` applies all three, so
  /// what is written here is only the state to be in if that never happens:
  /// recording off.
  ///
  /// Masking stays off, as it was pre-kit. A replay of a masked screen is grey
  /// boxes moving around and cannot show where a user got stuck, which is the
  /// only reason this app pays for replay. `session_replay_mask_text` and
  /// `session_replay_mask_images` can turn it on for everyone without a
  /// release if a screen ever renders something that should not be recorded.
  ///
  /// `debug` is still set unconditionally, so production builds log verbosely.
  /// That is a separate parity carry-over and is worth revisiting on its own.
  GenRevibesPostHogConfiguration get postHog => GenRevibesPostHogConfiguration(
        apiKey: postHogApiKey,
        debug: true,
      );

  /// FeedbackNest configuration.
  FeedbackNestConfiguration get feedbackNest =>
      FeedbackNestConfiguration(apiKey: feedbackNestApiKey);
}
