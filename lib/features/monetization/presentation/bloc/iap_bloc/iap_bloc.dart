import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/subscription.dart';
import '../../../domain/usecases/initialize_iap_usecase.dart';
import '../../../domain/usecases/refresh_subscription_usecase.dart';
import '../../../domain/usecases/restore_purchases_usecase.dart';
import '../../../domain/usecases/show_customer_center_usecase.dart';
import '../../../domain/usecases/show_paywall_usecase.dart';

part 'iap_event.dart';
part 'iap_state.dart';

class IapBloc extends Bloc<IapEvent, IapState> {
  IapBloc({
    required InitializeIapUseCase initializeIapUseCase,
    required RefreshSubscriptionUseCase refreshSubscriptionUseCase,
    required ShowPaywallUseCase showPaywallUseCase,
    required ShowCustomerCenterUseCase showCustomerCenterUseCase,
    required RestorePurchasesUseCase restorePurchasesUseCase,
  }) : _initialize = initializeIapUseCase,
       _refresh = refreshSubscriptionUseCase,
       _showPaywall = showPaywallUseCase,
       _showCustomerCenter = showCustomerCenterUseCase,
       _restorePurchases = restorePurchasesUseCase,
       super(const IapState()) {
    on<IapStarted>(_onStarted);
    on<IapRefreshRequested>(_onRefreshRequested);
    on<IapPaywallRequested>(_onPaywallRequested);
    on<IapCustomerCenterRequested>(_onCustomerCenterRequested);
    on<IapRestoreRequested>(_onRestoreRequested);
  }

  final InitializeIapUseCase _initialize;
  final RefreshSubscriptionUseCase _refresh;
  final ShowPaywallUseCase _showPaywall;
  final ShowCustomerCenterUseCase _showCustomerCenter;
  final RestorePurchasesUseCase _restorePurchases;

  Future<void> _onStarted(IapStarted event, Emitter<IapState> emit) =>
      _runSubscriptionOperation(_initialize, emit);

  Future<void> _onRefreshRequested(
    IapRefreshRequested event,
    Emitter<IapState> emit,
  ) => _runSubscriptionOperation(_refresh, emit);

  Future<void> _onPaywallRequested(
    IapPaywallRequested event,
    Emitter<IapState> emit,
  ) => _runSubscriptionOperation(_showPaywall, emit);

  Future<void> _onRestoreRequested(
    IapRestoreRequested event,
    Emitter<IapState> emit,
  ) => _runSubscriptionOperation(_restorePurchases, emit);

  Future<void> _onCustomerCenterRequested(
    IapCustomerCenterRequested event,
    Emitter<IapState> emit,
  ) async {
    final result = await _showCustomerCenter(NoParams.instance);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(clearMessage: true)),
    );
  }

  Future<void> _runSubscriptionOperation(
    BaseUseCase<Subscription, NoParams> operation,
    Emitter<IapState> emit,
  ) async {
    emit(state.copyWith(status: IapViewStatus.loading, clearMessage: true));
    final result = await operation(NoParams.instance);
    result.fold(
      (failure) => emit(
        state.copyWith(status: IapViewStatus.failure, message: failure.message),
      ),
      (subscription) => emit(
        state.copyWith(
          status: IapViewStatus.ready,
          isPremium: subscription.isPremium,
          clearMessage: true,
        ),
      ),
    );
  }
}
