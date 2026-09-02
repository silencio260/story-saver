import 'package:get_it/get_it.dart';
import 'app_rating/domain/repositories/app_rating_repository.dart';
import 'feedback/data/repositories/feedback_nest_repository_impl.dart';
import 'feedback/domain/repositories/feedback_repository.dart';
import 'gdpr/domain/repositories/gdpr_repository.dart';
import 'push_notifications/domain/repositories/push_notifications_repository.dart';
import 'remote_config/domain/repositories/remote_config_repository.dart';

/// Initialize Services dependencies
void initServicesFeature(
  GetIt sl, {
  RemoteConfigRepository? remoteConfigRepository,
  AppRatingRepository? appRatingRepository,
  GdprRepository? gdprRepository,
  PushNotificationsRepository? pushNotificationsRepository,
  FeedbackRepository? feedbackRepository,
  String? feedbackNestApiKey,
}) {
  // --- App Rating ---
  if (appRatingRepository != null) {
    sl.registerLazySingleton<AppRatingRepository>(() => appRatingRepository);
  }

  // --- Remote Config ---
  if (remoteConfigRepository != null) {
    sl.registerLazySingleton<RemoteConfigRepository>(
        () => remoteConfigRepository);
  }

  // --- GDPR ---
  if (gdprRepository != null) {
    sl.registerLazySingleton<GdprRepository>(() => gdprRepository);
  }

  // --- Feedback ---
  if (feedbackRepository != null) {
    sl.registerLazySingleton<FeedbackRepository>(() => feedbackRepository);
  } else if (feedbackNestApiKey != null && feedbackNestApiKey.isNotEmpty) {
    // Auto-wire the FeedbackNest implementation from the supplied API key.
    sl.registerLazySingleton<FeedbackRepository>(
      () => FeedbackNestRepositoryImpl(apiKey: feedbackNestApiKey),
    );
  }

  // --- Push Notifications ---
  if (pushNotificationsRepository != null) {
    sl.registerLazySingleton<PushNotificationsRepository>(
      () => pushNotificationsRepository,
    );
  }
}
