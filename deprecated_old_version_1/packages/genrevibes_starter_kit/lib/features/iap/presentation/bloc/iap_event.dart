part of 'iap_bloc.dart';

abstract class IapEvent extends Equatable {
  const IapEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize IAP service
class IapInitialize extends IapEvent {
  final String apiKey;

  const IapInitialize({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

/// Refresh subscription status
class IapRefreshStatus extends IapEvent {
  const IapRefreshStatus();
}

/// Load available products
class IapLoadProducts extends IapEvent {
  final List<String> productIds;

  const IapLoadProducts({required this.productIds});

  @override
  List<Object?> get props => [productIds];
}

/// Purchase a product
class IapPurchaseProduct extends IapEvent {
  final String productId;

  const IapPurchaseProduct({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Restore purchases
class IapRestorePurchases extends IapEvent {
  const IapRestorePurchases();
}

/// Debug: Toggle premium status
class IapDebugTogglePremium extends IapEvent {
  const IapDebugTogglePremium();
}
