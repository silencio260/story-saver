import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription_tier.dart';
import '../../domain/entities/user_profile_entity.dart';

/// Firestore model for user profile
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    required super.isAnonymous,
    super.tier = SubscriptionTier.free,
    super.subscriptionId,
    super.subscriptionStartDate,
    super.subscriptionRenewalDate,
    super.trialStartDate,
    super.trialEndDate,
    super.isTrialActive = false,
    super.subscriptionProvider,
    super.subscriptionMetadata = const {},
    super.usageStats = const {},
    super.preferences = const {},
    required super.createdAt,
    required super.updatedAt,
    super.lastActiveAt,
  });

  /// Create from Firestore document
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfileModel.fromJson(data, doc.id);
  }

  /// Create from JSON map
  factory UserProfileModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfileModel(
      uid: uid,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      tier: SubscriptionTierExtension.fromString(
        json['tier'] as String? ?? 'free',
      ),
      subscriptionId: json['subscriptionId'] as String?,
      subscriptionStartDate: _parseDateTime(json['subscriptionStartDate']),
      subscriptionRenewalDate: _parseDateTime(json['subscriptionRenewalDate']),
      trialStartDate: _parseDateTime(json['trialStartDate']),
      trialEndDate: _parseDateTime(json['trialEndDate']),
      isTrialActive: json['isTrialActive'] as bool? ?? false,
      subscriptionProvider: json['subscriptionProvider'] as String?,
      subscriptionMetadata: Map<String, dynamic>.from(
        json['subscriptionMetadata'] as Map? ?? {},
      ),
      usageStats: Map<String, int>.from(
        json['usageStats'] as Map? ?? {},
      ),
      preferences: Map<String, dynamic>.from(
        json['preferences'] as Map? ?? {},
      ),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      lastActiveAt: _parseDateTime(json['lastActiveAt']),
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'tier': tier.value,
      'subscriptionId': subscriptionId,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionRenewalDate': subscriptionRenewalDate?.toIso8601String(),
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'isTrialActive': isTrialActive,
      'subscriptionProvider': subscriptionProvider,
      'subscriptionMetadata': subscriptionMetadata,
      'usageStats': usageStats,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  /// Convert from entity
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      isAnonymous: entity.isAnonymous,
      tier: entity.tier,
      subscriptionId: entity.subscriptionId,
      subscriptionStartDate: entity.subscriptionStartDate,
      subscriptionRenewalDate: entity.subscriptionRenewalDate,
      trialStartDate: entity.trialStartDate,
      trialEndDate: entity.trialEndDate,
      isTrialActive: entity.isTrialActive,
      subscriptionProvider: entity.subscriptionProvider,
      subscriptionMetadata: entity.subscriptionMetadata,
      usageStats: entity.usageStats,
      preferences: entity.preferences,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastActiveAt: entity.lastActiveAt,
    );
  }

  /// Convert to domain entity
  UserProfileEntity toDomain() => this;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
