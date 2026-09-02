import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_profile_entity.dart';
import '../entities/subscription_tier.dart';

/// Abstract repository for user profile operations
abstract class UserProfileRepository {
  /// Get user profile by UID
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String uid);

  /// Get user profile by email
  Future<Either<Failure, UserProfileEntity?>> getUserProfileByEmail(
    String email,
  );

  /// Create a new user profile
  Future<Either<Failure, void>> createUserProfile(UserProfileEntity profile);

  /// Update existing user profile
  Future<Either<Failure, void>> updateUserProfile(UserProfileEntity profile);

  /// Update user preferences
  Future<Either<Failure, void>> updatePreferences(
    String uid,
    Map<String, dynamic> preferences,
  );

  /// Increment a usage counter (e.g., 'message', 'image_gen')
  Future<Either<Failure, void>> incrementUsage(String uid, String usageKey);

  /// Update subscription data
  Future<Either<Failure, void>> updateSubscription({
    required String uid,
    required SubscriptionTier tier,
    String? subscriptionId,
    DateTime? startDate,
    DateTime? renewalDate,
    String? provider,
    Map<String, dynamic>? metadata,
  });

  /// Update trial status
  Future<Either<Failure, void>> updateTrialStatus({
    required String uid,
    required bool isActive,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Stream of user profile changes
  Stream<UserProfileEntity?> userProfileStream(String uid);

  /// Update last active timestamp
  Future<Either<Failure, void>> updateLastActive(String uid);

  /// Delete user profile and all associated data
  Future<Either<Failure, void>> deleteUserProfile(String uid);
}
