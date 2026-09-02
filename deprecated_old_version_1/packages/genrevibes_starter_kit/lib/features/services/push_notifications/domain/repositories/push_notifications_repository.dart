import 'package:dartz/dartz.dart';

import '../../../../../core/error/failure.dart';

/// Repository for push notifications (OneSignal)
abstract class PushNotificationsRepository {
  /// Initialize push notifications service
  Future<Either<Failure, void>> initialize(String appId);

  /// Set user ID for push notifications
  Future<Either<Failure, void>> setUserId(String userId);

  /// Set email for push notifications
  Future<Either<Failure, void>> setEmail(String email);

  /// Set external user ID
  Future<Either<Failure, void>> setExternalUserId(String externalUserId);

  /// Send a tag (key-value pair)
  Future<Either<Failure, void>> sendTag(String key, String value);

  /// Send multiple tags
  Future<Either<Failure, void>> sendTags(Map<String, String> tags);

  /// Delete a tag
  Future<Either<Failure, void>> deleteTag(String key);

  /// Delete multiple tags
  Future<Either<Failure, void>> deleteTags(List<String> keys);

  /// Get the OneSignal player ID
  Future<Either<Failure, String?>> getPlayerId();

  /// Enable push notifications
  Future<Either<Failure, void>> enable();

  /// Disable push notifications
  Future<Either<Failure, void>> disable();

  /// Check if push notifications are enabled
  Future<Either<Failure, bool>> isEnabled();
}
