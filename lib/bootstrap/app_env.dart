import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_appodeal/genrevibes_ads_appodeal.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:genrevibes_feedbacknest/genrevibes_feedbacknest.dart';
import 'package:genrevibes_iap_revenuecat/genrevibes_iap_revenuecat.dart';
import 'package:genrevibes_notifications_onesignal/genrevibes_notifications_onesignal.dart';

/// Logical ad placements this app uses.
///
/// Placement IDs are stable and app-owned; the provider placement behind one
/// may change without the call sites moving.
abstract final class AppPlacements {
  /// Inline banner shown on the status and saved-media grids.
  static const banner = AdPlacement(id: 'banner', format: AdFormat.banner);

  /// Interstitial shown between full-screen media views.
  static const interstitial =
      AdPlacement(id: 'interstitial', format: AdFormat.interstitial);

  /// Every placement, for policy configuration.
  static const all = <AdPlacement>[banner, interstitial];
}

/// Phones that always have the developer tools and test ads, in every build.
///
/// Hashes, never device identifiers: this list is compiled into the app, so
/// whatever is here is public. Copy a phone's hash from Settings → Developer
/// Options → Copy Developer Device Hash, or Starter Kit Lab → Developer access.
///
/// For phones that come and go, use `developer_device_hashes` in the env file
/// or in remote config instead. Neither needs a code change, and remote config
/// needs no release.
abstract final class AppDeveloperDevices {
  /// Developer device hashes.
  static const hashes = <String>[];
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
    required this.appodealAndroidAppKey,
    this.appodealIosAppKey = '',
    this.forceSessionReplay = false,
    this.disableFirebaseAnalyticsInDebug = false,
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.developerPasscode = '',
    this.developerDeviceHashes = '',
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
      appodealAndroidAppKey:
          String.fromEnvironment('appodeal_app_key_android'),
      appodealIosAppKey: String.fromEnvironment('appodeal_app_key_ios'),
      forceSessionReplay: bool.fromEnvironment('posthog_session_replay'),
      disableFirebaseAnalyticsInDebug:
          bool.fromEnvironment('disabled_firebase_analytics_in_debug_mode'),
      privacyPolicyUrl: String.fromEnvironment('privacy_policy_url'),
      termsUrl: String.fromEnvironment('terms_url'),
      developerPasscode: String.fromEnvironment('developer_passcode'),
      developerDeviceHashes:
          String.fromEnvironment('developer_device_hashes'),
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

  /// Appodeal app key for Android, defined as `appodeal_app_key_android`.
  ///
  /// Development builds need the real key too: Appodeal's test mode is a switch
  /// on the SDK, which still initializes against the app. Without a key the ads
  /// and consent modules report themselves unconfigured.
  final String appodealAndroidAppKey;

  /// Appodeal app key for iOS, defined as `appodeal_app_key_ios`.
  final String appodealIosAppKey;

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

  /// Passcode for the hidden developer unlock in a store build.
  ///
  /// Defined as `developer_passcode` in `env/*.json`; blank means
  /// `DeveloperAccessDefaults.passcode`. Like every define it is compiled into
  /// the binary, so it stops casual discovery, not a determined attacker. The
  /// lockout after three wrong attempts is what stops guessing.
  final String developerPasscode;

  /// Developer device hashes from the env file, comma separated.
  ///
  /// Defined as `developer_device_hashes`. Hashes only — see
  /// [AppDeveloperDevices].
  final String developerDeviceHashes;

  /// Crash collection is off in development so local runs do not pollute
  /// production crash-free rates.
  CrashReportingConfig get crash =>
      CrashReportingConfig(collectionEnabled: !isDevelopment);

  /// The Appodeal app key for the platform this build runs on.
  String get appodealAppKey => defaultTargetPlatform == TargetPlatform.iOS
      ? appodealIosAppKey
      : appodealAndroidAppKey;

  /// Appodeal configuration for every placement this app shows.
  ///
  /// Both placements use the dashboard's `default` placement. Nothing here
  /// changes between live and test ads: test mode is a switch on the SDK, and
  /// `DeveloperAccessController` decides it when the provider starts.
  GenRevibesAppodealConfiguration get appodeal =>
      GenRevibesAppodealConfiguration(
        appKey: appodealAppKey,
        placements: const <AppodealPlacement>[
          AppodealPlacement(placement: AppPlacements.banner),
          AppodealPlacement(placement: AppPlacements.interstitial),
        ],
        verboseLogging: isDevelopment,
      );

  /// Who gets the developer tools and test ads in this build.
  ///
  /// The remote list is not here; it is bound at runtime by
  /// `DeveloperAccessRemotePolicyBinder`.
  DeveloperAccessConfig get developerAccess => DeveloperAccessConfig(
        isDevelopmentBuild: isDevelopment,
        hardcodedDeviceHashes: AppDeveloperDevices.hashes,
        environmentDeviceHashes: developerDeviceHashes,
        passcode: developerPasscode,
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
