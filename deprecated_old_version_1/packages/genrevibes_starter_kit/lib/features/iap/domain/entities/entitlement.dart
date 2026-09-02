import 'package:equatable/equatable.dart';

/// Represents an entitlement/subscription status
class Entitlement extends Equatable {
  final String id;
  final bool isActive;
  final DateTime? expirationDate;
  final String? productId;
  final bool willRenew;

  const Entitlement({
    required this.id,
    required this.isActive,
    this.expirationDate,
    this.productId,
    this.willRenew = false,
  });

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  @override
  List<Object?> get props => [id, isActive, expirationDate, productId];
}
