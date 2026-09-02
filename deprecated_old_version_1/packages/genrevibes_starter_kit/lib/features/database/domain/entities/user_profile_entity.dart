import 'package:equatable/equatable.dart';
import '../../../iap/domain/services/subscription_manager.dart';
import 'subscription_tier.dart';

/// User profile entity with subscription and usage data
///
/// Stored in Firestore: users/{uid}/profile
class UserProfileEntity extends Equatable {
  /// Unique user identifier from Firebase Auth
  final String uid;

  /// User's email address
  final String? email;

  /// User's display name
  final String? displayName;

  /// URL to user's profile photo
  final String? photoUrl;

  /// Whether this is an anonymous account
  final bool isAnonymous;

  // ============== Subscription Data ==============

  /// Current subscription tier
  final SubscriptionTier tier;

  /// IAP subscription ID (RevenueCat or other provider)
  final String? subscriptionId;

  /// When the subscription started
  final DateTime? subscriptionStartDate;

  /// When the subscription renews/expires
  final DateTime? subscriptionRenewalDate;

  /// Trial start date (if applicable)
  final DateTime? trialStartDate;

  /// Trial end date (if applicable)
  final DateTime? trialEndDate;

  /// Whether trial is currently active
  final bool isTrialActive;

  /// IAP provider name for easy migration
  final String? subscriptionProvider;

  /// Flexible metadata for provider-specific data
  final Map<String, dynamic> subscriptionMetadata;

  // ============== Usage Tracking ==============

  /// Map of usage counters (e.g., {'message': 10, 'image': 2})
  final Map<String, int> usageStats;

  // ============== Preferences ==============

  /// User preferences map
  final Map<String, dynamic> preferences;

  // ============== Timestamps ==============

  /// When the profile was created
  final DateTime createdAt;

  /// Last profile update
  final DateTime updatedAt;

  /// Last user activity
  final DateTime? lastActiveAt;

  const UserProfileEntity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    this.tier = SubscriptionTier.free,
    this.subscriptionId,
    this.subscriptionStartDate,
    this.subscriptionRenewalDate,
    this.trialStartDate,
    this.trialEndDate,
    this.isTrialActive = false,
    this.subscriptionProvider,
    this.subscriptionMetadata = const {},
    this.usageStats = const {},
    this.preferences = const {},
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
  });

  /// Create initial profile for a new user
  factory UserProfileEntity.initial({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
    required bool isAnonymous,
  }) {
    final now = DateTime.now();
    return UserProfileEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isAnonymous: isAnonymous,
      tier: SubscriptionTier.free,
      createdAt: now,
      updatedAt: now,
      lastActiveAt: now,
    );
  }

  /// Check if user has active subscription or trial
  bool get hasActiveSubscription {
    if (tier == SubscriptionTier.pro) return true;
    if (isTrialActive && trialEndDate != null) {
      return DateTime.now().isBefore(trialEndDate!);
    }
    return false;
  }

  /// Get effective tier (considering trial and debug override)
  SubscriptionTier get effectiveTier {
    if (hasActiveSubscription || SubscriptionManager.instance.isPremium) {
      return SubscriptionTier.pro;
    }
    return tier;
  }

  UserProfileEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    SubscriptionTier? tier,
    String? subscriptionId,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionRenewalDate,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    bool? isTrialActive,
    String? subscriptionProvider,
    Map<String, dynamic>? subscriptionMetadata,
    Map<String, int>? usageStats,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfileEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      tier: tier ?? this.tier,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionRenewalDate:
          subscriptionRenewalDate ?? this.subscriptionRenewalDate,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      subscriptionProvider: subscriptionProvider ?? this.subscriptionProvider,
      subscriptionMetadata: subscriptionMetadata ?? this.subscriptionMetadata,
      usageStats: usageStats ?? this.usageStats,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        isAnonymous,
        tier,
        subscriptionId,
        subscriptionStartDate,
        subscriptionRenewalDate,
        trialStartDate,
        trialEndDate,
        isTrialActive,
        subscriptionProvider,
        subscriptionMetadata,
        usageStats,
        preferences,
        createdAt,
        updatedAt,
        lastActiveAt,
      ];
}
