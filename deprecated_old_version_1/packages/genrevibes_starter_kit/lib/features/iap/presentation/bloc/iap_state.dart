part of 'iap_bloc.dart';

abstract class IapState extends Equatable {
  const IapState();

  @override
  List<Object?> get props => [];
}

/// Initial state before initialization
class IapInitial extends IapState {
  const IapInitial();
}

/// Loading state
class IapLoading extends IapState {
  const IapLoading();
}

/// IAP successfully initialized
class IapInitialized extends IapState {
  final SubscriptionStatus status;

  const IapInitialized({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Products loaded successfully
class IapProductsLoaded extends IapState {
  final List<Product> products;
  final SubscriptionStatus status;

  const IapProductsLoaded({required this.products, required this.status});

  @override
  List<Object?> get props => [products, status];
}

/// Purchase in progress
class IapPurchasing extends IapState {
  final String productId;

  const IapPurchasing({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Purchase successful
class IapPurchaseSuccess extends IapState {
  final SubscriptionStatus status;

  const IapPurchaseSuccess({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Restore in progress
class IapRestoring extends IapState {
  const IapRestoring();
}

/// Restore successful
class IapRestoreSuccess extends IapState {
  final SubscriptionStatus status;

  const IapRestoreSuccess({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Error state
class IapError extends IapState {
  final String message;

  const IapError({required this.message});

  @override
  List<Object?> get props => [message];
}
