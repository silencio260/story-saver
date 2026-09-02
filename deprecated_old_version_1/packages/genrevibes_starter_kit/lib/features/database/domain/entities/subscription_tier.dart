/// Subscription tier enum
enum SubscriptionTier {
  free,
  pro,
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get value {
    switch (this) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.pro:
        return 'pro';
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pro':
      case 'premium':
        return SubscriptionTier.pro;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  /// Check if user has pro features
  bool get isPro => this == SubscriptionTier.pro;

  /// Check if user can access pro AI models
  bool get canAccessProModels => isPro;

  /// Check if user can generate images
  bool get canGenerateImages => isPro;

  /// Check if user can upload files
  bool get canUploadFiles => isPro;
}
