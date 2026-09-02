part of 'iap_bloc.dart';

sealed class IapEvent extends Equatable {
  const IapEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class IapStarted extends IapEvent {
  const IapStarted();
}

class IapRefreshRequested extends IapEvent {
  const IapRefreshRequested();
}

class IapPaywallRequested extends IapEvent {
  const IapPaywallRequested();
}

class IapCustomerCenterRequested extends IapEvent {
  const IapCustomerCenterRequested();
}

class IapRestoreRequested extends IapEvent {
  const IapRestoreRequested();
}
