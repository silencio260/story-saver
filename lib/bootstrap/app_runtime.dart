import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_engagement/genrevibes_engagement.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';

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
  });

  /// The module coordinator.
  final GenRevibesStarterKit kit;

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

  /// Whether every required module started.
  bool get isHealthy => initialization.isSuccess;
}
