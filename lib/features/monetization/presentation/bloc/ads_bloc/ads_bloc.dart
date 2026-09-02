import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/usecases/dispose_ads_usecase.dart';
import '../../../domain/usecases/load_interstitial_ad_usecase.dart';
import '../../../domain/usecases/show_interstitial_ad_usecase.dart';
import '../../controllers/legacy/ad_suppression_manager.dart';

part 'ads_event.dart';
part 'ads_state.dart';

class AdsBloc extends Bloc<AdsEvent, AdsState> {
  AdsBloc({
    required LoadInterstitialAdUseCase loadInterstitialAdUseCase,
    required ShowInterstitialAdUseCase showInterstitialAdUseCase,
    required DisposeAdsUseCase disposeAdsUseCase,
    required AdSuppressionManager adSuppressionManager,
  }) : _loadInterstitial = loadInterstitialAdUseCase,
       _showInterstitial = showInterstitialAdUseCase,
       _disposeAds = disposeAdsUseCase,
       _adSuppressionManager = adSuppressionManager,
       super(const AdsState()) {
    on<AdsStarted>(_onStarted);
    on<InterstitialAdRequested>(_onInterstitialRequested);
    on<AdsDisabled>(_onDisabled);
    on<AdsSuppressionChanged>(_onSuppressionChanged);
    _adSuppressionManager.addListener(_onLegacySuppressionChanged);
  }

  final LoadInterstitialAdUseCase _loadInterstitial;
  final ShowInterstitialAdUseCase _showInterstitial;
  final DisposeAdsUseCase _disposeAds;
  final AdSuppressionManager _adSuppressionManager;

  Future<void> _onStarted(AdsStarted event, Emitter<AdsState> emit) async {
    if (_adSuppressionManager.areAdsSuppressed) {
      emit(const AdsState(status: AdsViewStatus.disabled));
      return;
    }
    final result = await _loadInterstitial(NoParams.instance);
    result.fold(
      (failure) => emit(
        AdsState(status: AdsViewStatus.failure, message: failure.message),
      ),
      (_) => emit(const AdsState(status: AdsViewStatus.ready)),
    );
  }

  Future<void> _onInterstitialRequested(
    InterstitialAdRequested event,
    Emitter<AdsState> emit,
  ) async {
    if (_adSuppressionManager.areAdsSuppressed) return;
    final result = await _showInterstitial(NoParams.instance);
    result.fold(
      (failure) => emit(
        AdsState(status: AdsViewStatus.failure, message: failure.message),
      ),
      (shown) => emit(
        AdsState(status: AdsViewStatus.ready, interstitialWasShown: shown),
      ),
    );
  }

  Future<void> _onDisabled(AdsDisabled event, Emitter<AdsState> emit) async {
    await _disposeAds(NoParams.instance);
    emit(const AdsState(status: AdsViewStatus.disabled));
  }

  Future<void> _onSuppressionChanged(
    AdsSuppressionChanged event,
    Emitter<AdsState> emit,
  ) async {
    if (event.isSuppressed) {
      await _disposeAds(NoParams.instance);
      emit(const AdsState(status: AdsViewStatus.disabled));
    } else {
      add(const AdsStarted());
    }
  }

  void _onLegacySuppressionChanged() {
    add(AdsSuppressionChanged(_adSuppressionManager.areAdsSuppressed));
  }

  @override
  Future<void> close() {
    _adSuppressionManager.removeListener(_onLegacySuppressionChanged);
    return super.close();
  }
}
