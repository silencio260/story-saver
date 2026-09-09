import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_app_links/genrevibes_app_links.dart';
import 'package:genrevibes_app_rating/genrevibes_app_rating.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_devtools/genrevibes_devtools.dart';
import 'package:genrevibes_engagement/genrevibes_engagement.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_permissions/genrevibes_permissions.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';

import 'app_env.dart';

/// Everything the composition root built, ready to hand to dependency
/// injection.
///
/// This is a value object, not a service locator. It holds instances; it does
/// not resolve them. `registerRuntime` is what puts them into GetIt.
final class AppRuntime {
  /// Creates a runtime.
  const AppRuntime({
    required this.kit,
    required this.initialization,
    required this.store,
    required this.crash,
    required this.identity,
    required this.consent,
    required this.analytics,
    required this.adPolicy,
    required this.ads,
    required this.iap,
    required this.push,
    required this.feedback,
    required this.remoteConfig,
    required this.retention,
    required this.permissions,
    required this.links,
    required this.linkOpener,
    required this.rating,
    required this.storeReview,
    required this.localNotifications,
    required this.bannerAdUnit,
    required this.env,
    this.eventLog,
    this.kitLog,
  });

  /// The module coordinator.
  final GenRevibesStarterKit kit;

  /// Build-time configuration, for the few call sites that need a value the
  /// kit does not model — an ad unit id on an analytics property, say.
  final AppEnv env;

  /// Result of `kit.initialize()`.
  ///
  /// A failure here means a required module did not start. It is kept rather
  /// than discarded so the health screen can show what went wrong; the old
  /// `main()` threw away the equivalent `Either` and left partial
  /// initialization invisible.
  final KitResult<void> initialization;

  /// Shared key-value storage, with legacy key adoption.
  final KeyValueStore store;

  /// Crash reporting.
  final CrashCoordinator crash;

  /// Stable install identity.
  final DeviceIdentityResolver identity;

  /// Privacy consent gate.
  final ConsentGate consent;

  /// Analytics fan-out.
  final AnalyticsPipeline analytics;

  /// Ad timing and suppression policy.
  ///
  /// Live and receiving premium updates, but nothing reads it until the ads
  /// migration replaces `AdsBloc`.
  final AdPolicyController adPolicy;

  /// Ad provider. Owns `MobileAds.initialize()`.
  final AdProvider ads;

  /// Purchases and entitlements.
  final IapProvider iap;

  /// Remote push.
  final PushNotificationProvider push;

  /// User feedback submission.
  final FeedbackProvider feedback;

  /// Typed remote configuration.
  final RemoteConfigCoordinator remoteConfig;

  /// Retention history, milestones and targeting.
  final RetentionTracker retention;

  /// Runtime permissions.
  final PermissionProvider permissions;

  /// Share, store, support, privacy and terms actions.
  ///
  /// Policy — which URL for which platform, what the share text says — lives in
  /// the kit's [AppLinkActions]; the app supplies the configuration and calls
  /// these instead of building `Uri`s at call sites.
  final AppLinkActions links;

  /// The raw opener behind [links], for call sites that must launch a URI the
  /// kit has no named action for — a `whatsapp://` deep link, for instance.
  final LinkOpener linkOpener;

  /// Rating eligibility, cooldowns and outcome recording.
  final RatingCoordinator rating;

  /// The store review flow behind [rating].
  final StoreReviewProvider storeReview;

  /// Device-local notifications.
  final LocalNotificationScheduler localNotifications;

  /// The inline banner unit.
  ///
  /// Inline formats are not owned by [ads]: `AdMobAdProvider` handles only
  /// full-screen placements, and passing it a banner unit fails the whole ads
  /// module. The banner is rendered by the widget in `genrevibes_ads_admob_ui`,
  /// which needs this unit directly.
  final AdMobAdUnit bannerAdUnit;

  /// Analytics deliveries captured in development, for the Lab's event log.
  final RecordingDeliveryObserver? eventLog;

  /// Kit module logs captured in development.
  final RecordingKitLogger? kitLog;

  /// Whether every required module started.
  bool get isHealthy => initialization.isSuccess;
}
