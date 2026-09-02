import 'package:equatable/equatable.dart';

/// Represents subscription/premium status
class SubscriptionStatus extends Equatable {
  final bool isPremium;
  final String? activeEntitlementId;
  final DateTime? expirationDate;
  final bool willRenew;
  final String? activeProductId;

  const SubscriptionStatus({
    required this.isPremium,
    this.activeEntitlementId,
    this.expirationDate,
    this.willRenew = false,
    this.activeProductId,
  });

  const SubscriptionStatus.free()
    : isPremium = false,
      activeEntitlementId = null,
      expirationDate = null,
      willRenew = false,
      activeProductId = null;

  @override
  List<Object?> get props => [
    isPremium,
    activeEntitlementId,
    expirationDate,
    willRenew,
    activeProductId,
  ];
}
