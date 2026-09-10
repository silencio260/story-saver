import 'package:genrevibes_ads/genrevibes_ads.dart';

import 'app_env.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_app_links/genrevibes_app_links.dart';
import 'package:genrevibes_app_rating/genrevibes_app_rating.dart';
import 'package:genrevibes_onboarding/genrevibes_onboarding.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_engagement/genrevibes_engagement.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_permissions/genrevibes_permissions.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';

import '../container_injector.dart';
import 'app_runtime.dart';

/// Registers the composed kit instances so existing use cases and BLoCs can
/// resolve them exactly as they resolve repositories today.
///
/// The kit never sees GetIt. Composition happens in `bootstrapApp`; this
/// function only publishes the result. Call it once, before
/// `initAppDependencies()`, since the container has no `allowReassignment` and
/// no `reset()`.
void registerRuntime(AppRuntime runtime) {
  sl
    ..registerSingleton<AppRuntime>(runtime)
    ..registerSingleton<GenRevibesStarterKit>(runtime.kit)
    ..registerSingleton<KeyValueStore>(runtime.store)
    ..registerSingleton<CrashCoordinator>(runtime.crash)
    ..registerSingleton<DeviceIdentityResolver>(runtime.identity)
    ..registerSingleton<ConsentGate>(runtime.consent)
    ..registerSingleton<AnalyticsPipeline>(runtime.analytics)
    ..registerSingleton<AdPolicyController>(runtime.adPolicy)
    ..registerSingleton<AdProvider>(runtime.ads)
    ..registerSingleton<IapProvider>(runtime.iap)
    ..registerSingleton<PushNotificationProvider>(runtime.push)
    ..registerSingleton<FeedbackProvider>(runtime.feedback)
    ..registerSingleton<RemoteConfigCoordinator>(runtime.remoteConfig)
    ..registerSingleton<SessionReplayController>(runtime.sessionReplay)
    ..registerSingleton<RetentionTracker>(runtime.retention)
    ..registerSingleton<PermissionProvider>(runtime.permissions)
    ..registerSingleton<AppLinkActions>(runtime.links)
    ..registerSingleton<LinkOpener>(runtime.linkOpener)
    ..registerSingleton<RatingCoordinator>(runtime.rating)
    ..registerSingleton<StoreReviewProvider>(runtime.storeReview)
    ..registerSingleton<LocalNotificationScheduler>(
      runtime.localNotifications,
    )
    ..registerSingleton<AdMobAdUnit>(runtime.bannerAdUnit)
    ..registerSingleton<AppEnv>(runtime.env)
    ..registerSingleton<OnboardingController>(runtime.onboarding);
}
