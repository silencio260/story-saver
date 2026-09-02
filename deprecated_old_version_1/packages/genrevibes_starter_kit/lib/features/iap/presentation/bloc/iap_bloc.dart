import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/get_subscription_status_usecase.dart';
import '../../domain/usecases/initialize_iap_usecase.dart';
import '../../domain/usecases/purchase_product_usecase.dart';
import '../../domain/usecases/restore_purchases_usecase.dart';
import '../../domain/services/subscription_manager.dart';
import '../../../../core/utils/starter_log.dart';

part 'iap_event.dart';
part 'iap_state.dart';

/// IAP Bloc for managing subscription state
class IapBloc extends Bloc<IapEvent, IapState> {
  final GetSubscriptionStatusUseCase getSubscriptionStatusUseCase;
  final InitializeIapUseCase initializeIapUseCase;
  final GetProductsUseCase getProductsUseCase;
  final PurchaseProductUseCase purchaseProductUseCase;
  final RestorePurchasesUseCase restorePurchasesUseCase;

  SubscriptionStatus _currentStatus = const SubscriptionStatus.free();
  List<Product> _products = [];

  /// Quick getter for premium status
  bool get isPremium => SubscriptionManager.instance.isPremium;

  /// Current subscription status
  SubscriptionStatus get currentStatus => _currentStatus;

  /// Available products
  List<Product> get products => _products;

  IapBloc({
    required this.initializeIapUseCase,
    required this.getSubscriptionStatusUseCase,
    required this.getProductsUseCase,
    required this.purchaseProductUseCase,
    required this.restorePurchasesUseCase,
  }) : super(const IapInitial()) {
    on<IapInitialize>(_onInitialize);
    on<IapRefreshStatus>(_onRefreshStatus);
    on<IapLoadProducts>(_onLoadProducts);
    on<IapPurchaseProduct>(_onPurchaseProduct);
    on<IapRestorePurchases>(_onRestorePurchases);
    on<IapDebugTogglePremium>(_onDebugTogglePremium);

    // Listen to external subscription changes (e.g., from SubscriptionManager direct calls)
    SubscriptionManager.instance.addListener(_onSubscriptionManagerNotify);
  }

  void _onSubscriptionManagerNotify() {
    // Refresh status when manager notifies
    if (!isClosed) {
      add(const IapRefreshStatus());
    }
  }

  @override
  Future<void> close() {
    SubscriptionManager.instance.removeListener(_onSubscriptionManagerNotify);
    return super.close();
  }

  Future<void> _onInitialize(
    IapInitialize event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapLoading());

    final result = await initializeIapUseCase(event.apiKey);
    result.fold(
      (failure) {
        StarterLog.e(
          'Failed to initialize IAP',
          tag: 'IAP',
          error: failure.message,
        );
        emit(IapError(message: failure.message));
      },
      (_) {
        StarterLog.i('IAP initialized successfully', tag: 'IAP');
        // After successful initialization, refresh the status
        add(const IapRefreshStatus());
      },
    );
  }

  Future<void> _onDebugTogglePremium(
    IapDebugTogglePremium event,
    Emitter<IapState> emit,
  ) async {
    // Never construct fake entitlements in release builds.
    if (!kDebugMode) return;

    final newStatus = _currentStatus.isPremium
        ? const SubscriptionStatus.free()
        : SubscriptionStatus(
            isPremium: true,
            activeEntitlementId: 'debug_entitlement',
            activeProductId: 'debug_product',
            expirationDate: DateTime.now().add(const Duration(days: 1)),
            willRenew: true,
          );

    _currentStatus = newStatus;
    SubscriptionManager.instance.updateStatus(newStatus);
    emit(IapInitialized(status: newStatus));

    StarterLog.i(
      'Debug: Premium Toggled to ${newStatus.isPremium}',
      tag: 'IAP',
    );
  }

  Future<void> _onRefreshStatus(
    IapRefreshStatus event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapLoading());

    final result = await getSubscriptionStatusUseCase();
    result.fold(
      (failure) {
        StarterLog.e(
          'Failed to refresh sub status',
          tag: 'IAP',
          error: failure.message,
        );
        emit(IapError(message: failure.message));
      },
      (status) {
        StarterLog.i(
          'Subscription status updated',
          tag: 'IAP',
          values: {
            'Is Premium': status.isPremium,
            'Entitlement': status.activeEntitlementId ?? 'none',
          },
        );
        _currentStatus = status;
        SubscriptionManager.instance.updateStatus(status);
        emit(IapInitialized(status: status));
      },
    );
  }

  Future<void> _onLoadProducts(
    IapLoadProducts event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapLoading());

    final result = await getProductsUseCase(event.productIds);
    result.fold(
      (failure) {
        StarterLog.e(
          'Failed to load products',
          tag: 'IAP',
          error: failure.message,
        );
        emit(IapError(message: failure.message));
      },
      (products) {
        StarterLog.i(
          'Products loaded successfully',
          tag: 'IAP',
          values: {
            'Count': products.length,
            'Items': products.map((p) => '${p.id} (${p.price})').join(', '),
          },
        );
        _products = products;
        emit(IapProductsLoaded(products: products, status: _currentStatus));
      },
    );
  }

  Future<void> _onPurchaseProduct(
    IapPurchaseProduct event,
    Emitter<IapState> emit,
  ) async {
    emit(IapPurchasing(productId: event.productId));

    final result = await purchaseProductUseCase(event.productId);
    result.fold(
      (failure) {
        StarterLog.e(
          'Purchase failed',
          tag: 'IAP',
          error: failure.message,
          values: {'ProductID': event.productId},
        );
        emit(IapError(message: failure.message));
      },
      (status) {
        StarterLog.i(
          'Purchase success!',
          tag: 'IAP',
          values: {
            'ProductID': event.productId,
            'Status': status.isPremium ? 'Active' : 'Missing Entitlement',
          },
        );
        _currentStatus = status;
        SubscriptionManager.instance.updateStatus(status);
        emit(IapPurchaseSuccess(status: status));
      },
    );
  }

  Future<void> _onRestorePurchases(
    IapRestorePurchases event,
    Emitter<IapState> emit,
  ) async {
    emit(const IapRestoring());

    final result = await restorePurchasesUseCase();
    result.fold((failure) => emit(IapError(message: failure.message)), (
      status,
    ) {
      _currentStatus = status;
      SubscriptionManager.instance.updateStatus(status);
      emit(IapRestoreSuccess(status: status));
    });
  }
}
