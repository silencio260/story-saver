import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
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

  /// Crash collection is off in development so local runs do not pollute
  /// production crash-free rates.
  CrashReportingConfig get crash =>
      CrashReportingConfig(collectionEnabled: !isDevelopment);

  /// Consent debug overrides.
  ///
  /// Inactive outside development. The previous implementation hardcoded an
  /// EEA geography in every build, which forced the consent form on users who
  /// should never have seen it.
  ConsentDebugConfig get consentDebug => isDevelopment
      ? const ConsentDebugConfig(
          geography: ConsentDebugGeography.europeanEconomicArea,
        )
      : const ConsentDebugConfig();

  /// The banner unit, for `AdMobBannerView`.
  ///
  /// Deliberately not part of [adMob]. `AdMobAdProvider` serves the
  /// full-screen formats only — interstitial, rewarded and app-open — and
  /// rejects a banner unit at initialization, which took the whole ads module
  /// down with it. Inline formats are rendered by the widget in
  /// `genrevibes_ads_admob_ui`, which holds its own unit. The ads migration
  /// consumes this; nothing reads it yet.
  AdMobAdUnit get bannerAdUnit => AdMobAdUnit(
        placement: AppPlacements.banner,
        adUnitId: bannerAdUnitId,
      );

  /// AdMob configuration for the full-screen placements this app declares.
  GenRevibesAdMobConfiguration get adMob => GenRevibesAdMobConfiguration(
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

  /// PostHog configuration.
  ///
  /// These values reproduce `PostHogWrapper.init()` exactly, because this stage
  /// is a parity migration. Two of them are worth revisiting separately, and
  /// deliberately are not changed here:
  ///
  /// - `debug` was set unconditionally, so production builds log verbosely.
  /// - Session replay runs in production with `maskAllTexts` and
  ///   `maskAllImages` both false, so replays capture text and images
  ///   unmasked. The kit's defaults are the privacy-first opposite.
  GenRevibesPostHogConfiguration get postHog => GenRevibesPostHogConfiguration(
        apiKey: postHogApiKey,
        debug: true,
        sessionReplayEnabled: !isDevelopment,
        maskAllTexts: false,
        maskAllImages: false,
      );

  /// FeedbackNest configuration.
  FeedbackNestConfiguration get feedbackNest =>
      FeedbackNestConfiguration(apiKey: feedbackNestApiKey);
}
