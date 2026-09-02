import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ad_reward.dart';
import '../../domain/entities/ad_unit.dart';
import '../../domain/usecases/show_interstitial_usecase.dart';
import '../../domain/usecases/show_rewarded_usecase.dart';
import '../../domain/usecases/show_app_open_usecase.dart';
import '../../domain/repositories/ads_repository.dart';
import '../../domain/services/ad_suppression_manager.dart';
import '../../../analytics/domain/entities/ad_revenue_event.dart';
import '../../../../core/utils/starter_log.dart';

part 'ads_event.dart';
part 'ads_state.dart';

/// Ads Bloc for managing ad display
class AdsBloc extends Bloc<AdsEvent, AdsState> {
  final AdsRepository adsRepository;
  final ShowInterstitialUseCase showInterstitialUseCase;
  final ShowRewardedUseCase showRewardedUseCase;
  final ShowAppOpenUseCase showAppOpenUseCase;
  final void Function(AdRevenueEvent)? onPaidEvent;

  AdsConfig? _currentConfig;
  DateTime? _lastInterstitialTime;
  DateTime? _lastRewardedTime;
  DateTime? _lastNativeTime;
  DateTime? _lastAppOpenTime;
  late DateTime _sessionStartTime;

  AdsBloc({
    required this.adsRepository,
    required this.showInterstitialUseCase,
    required this.showRewardedUseCase,
    required this.showAppOpenUseCase,
    this.onPaidEvent,
  }) : super(const AdsInitial()) {
    _sessionStartTime = DateTime.now();
    on<AdsInitialize>(_onInitialize);
    on<AdsLoadInterstitial>(_onLoadInterstitial);
    on<AdsShowInterstitial>(_onShowInterstitial);
    on<AdsLoadRewarded>(_onLoadRewarded);
    on<AdsShowRewarded>(_onShowRewarded);
    on<AdsLoadAppOpen>(_onLoadAppOpen);
    on<AdsShowAppOpen>(_onShowAppOpen);
    on<AdsLoadNative>(_onLoadNative);
  }

  Future<void> _onInitialize(
    AdsInitialize event,
    Emitter<AdsState> emit,
  ) async {
    _currentConfig = event.config;
    _sessionStartTime = DateTime.now();
    emit(AdsLoading(config: _currentConfig));
    final result = await adsRepository.initialize(event.config);
    result.fold(
      (failure) {
        StarterLog.e(
          'Failed to initialize Ads',
          tag: 'ADS',
          error: failure.message,
        );
        emit(AdsError(message: failure.message, config: _currentConfig));
      },
      (_) {
        StarterLog.i(
          'Ads initialized successfully',
          tag: 'ADS',
          values: {
            'Interstitial': event.config.interstitialAdUnitId ?? 'none',
            'Rewarded': event.config.rewardedAdUnitId ?? 'none',
            'AppOpen': event.config.appOpenAdUnitId ?? 'none',
            'Native': event.config.nativeAdUnitId ?? 'none',
          },
        );
        emit(AdsInitialized(config: _currentConfig));

        // Trigger initial loads for all configured ad types
        if (event.config.interstitialAdUnitId != null) {
          add(AdsLoadInterstitial(
              adUnitId: event.config.interstitialAdUnitId!));
        }
        if (event.config.rewardedAdUnitId != null) {
          add(AdsLoadRewarded(adUnitId: event.config.rewardedAdUnitId!));
        }
        if (event.config.appOpenAdUnitId != null) {
          add(AdsLoadAppOpen(adUnitId: event.config.appOpenAdUnitId!));
        }
      },
    );
  }

  Future<void> _onLoadInterstitial(
    AdsLoadInterstitial event,
    Emitter<AdsState> emit,
  ) async {
    final result = await adsRepository.loadInterstitial(event.adUnitId);
    if (result.isLeft()) {
      result.fold(
        (failure) =>
            emit(AdsError(message: failure.message, config: _currentConfig)),
        (_) {},
      );
    } else {
      final ready = await _checkReadyStatus();
      if (!emit.isDone) emit(ready);
    }
  }

  Future<void> _onShowInterstitial(
    AdsShowInterstitial event,
    Emitter<AdsState> emit,
  ) async {
    final now = DateTime.now();

    // Check suppression (Paywalls, Modals, or another Ad already showing)
    if (AdSuppressionManager.instance.areAdsSuppressed) {
      StarterLog.d(
        'Interstitial suppressed',
        tag: 'ADS',
        values: {'reason': 'AdSuppressionManager (Active modal or premium)'},
      );
      return;
    }

    // Check first ad delay
    if (now.difference(_sessionStartTime).inSeconds <
        (_currentConfig?.timeBeforeFirstInstaAd ?? 0)) {
      return;
    }

    // Check interval since last ad
    if (_lastInterstitialTime != null &&
        now.difference(_lastInterstitialTime!).inSeconds <
            (_currentConfig?.minInterstitialInterval ?? 0)) {
      return;
    }

    AdSuppressionManager.instance.setAdShowing(true);
    final result = await showInterstitialUseCase();
    AdSuppressionManager.instance.setAdShowing(false);

    result.fold(
      (failure) {
        emit(AdsError(message: failure.message, config: _currentConfig));
        // Reload after failure
        if (_currentConfig?.interstitialAdUnitId != null) {
          add(AdsLoadInterstitial(
              adUnitId: _currentConfig!.interstitialAdUnitId!));
        }
      },
      (shown) {
        if (shown) {
          _lastInterstitialTime = DateTime.now();
          emit(
            AdsShowSuccess(type: AdType.interstitial, config: _currentConfig),
          );
          // Reload after show
          if (_currentConfig?.interstitialAdUnitId != null) {
            add(AdsLoadInterstitial(
                adUnitId: _currentConfig!.interstitialAdUnitId!));
          }
        }
      },
    );
  }

  Future<void> _onLoadRewarded(
    AdsLoadRewarded event,
    Emitter<AdsState> emit,
  ) async {
    final result = await adsRepository.loadRewarded(event.adUnitId);
    if (result.isLeft()) {
      result.fold(
        (failure) =>
            emit(AdsError(message: failure.message, config: _currentConfig)),
        (_) {},
      );
    } else {
      final ready = await _checkReadyStatus();
      if (!emit.isDone) emit(ready);
    }
  }

  Future<void> _onShowRewarded(
    AdsShowRewarded event,
    Emitter<AdsState> emit,
  ) async {
    final now = DateTime.now();

    // Check suppression
    if (AdSuppressionManager.instance.areAdsSuppressed) {
      StarterLog.d(
        'Rewarded ad suppressed',
        tag: 'ADS',
        values: {'reason': 'AdSuppressionManager'},
      );
      return;
    }

    // Check first ad delay
    if (now.difference(_sessionStartTime).inSeconds <
        (_currentConfig?.timeBeforeFirstRewardedAd ?? 0)) {
      return;
    }

    // Check interval since last ad
    if (_lastRewardedTime != null &&
        now.difference(_lastRewardedTime!).inSeconds <
            (_currentConfig?.minRewardedInterval ?? 0)) {
      return;
    }

    AdSuppressionManager.instance.setAdShowing(true);
    final result = await showRewardedUseCase();
    AdSuppressionManager.instance.setAdShowing(false);

    result.fold(
      (failure) {
        emit(AdsError(message: failure.message, config: _currentConfig));
        // Reload after failure
        if (_currentConfig?.rewardedAdUnitId != null) {
          add(AdsLoadRewarded(adUnitId: _currentConfig!.rewardedAdUnitId!));
        }
      },
      (reward) {
        StarterLog.i(
          'Rewarded ad show success',
          tag: 'ADS',
          values: {'Type': reward.type, 'Amount': reward.amount},
        );
        _lastRewardedTime = DateTime.now();
        emit(
          AdsShowSuccess(
            type: AdType.rewarded,
            reward: reward,
            config: _currentConfig,
          ),
        );
        // Reload after show
        if (_currentConfig?.rewardedAdUnitId != null) {
          add(AdsLoadRewarded(adUnitId: _currentConfig!.rewardedAdUnitId!));
        }
      },
    );
  }

  Future<void> _onLoadAppOpen(
    AdsLoadAppOpen event,
    Emitter<AdsState> emit,
  ) async {
    final result = await adsRepository.loadAppOpen(event.adUnitId);
    if (result.isLeft()) {
      result.fold(
        (failure) =>
            emit(AdsError(message: failure.message, config: _currentConfig)),
        (_) {},
      );
    } else {
      final ready = await _checkReadyStatus();
      if (!emit.isDone) emit(ready);
    }
  }

  Future<void> _onShowAppOpen(
    AdsShowAppOpen event,
    Emitter<AdsState> emit,
  ) async {
    if (_currentConfig?.shouldShowAppOpenAd == false) return;

    // Check suppression
    if (AdSuppressionManager.instance.areAdsSuppressed) {
      StarterLog.d(
        'AppOpen ad suppressed',
        tag: 'ADS',
        values: {'reason': 'AdSuppressionManager'},
      );
      return;
    }

    final now = DateTime.now();
    if (_lastAppOpenTime != null &&
        now.difference(_lastAppOpenTime!).inSeconds <
            (_currentConfig?.minAppOpenInterval ?? 0)) {
      return;
    }

    AdSuppressionManager.instance.setAdShowing(true);
    final result = await showAppOpenUseCase();
    AdSuppressionManager.instance.setAdShowing(false);

    result.fold(
      (failure) {
        emit(AdsError(message: failure.message, config: _currentConfig));
        // Reload after failure
        if (_currentConfig?.appOpenAdUnitId != null) {
          add(AdsLoadAppOpen(adUnitId: _currentConfig!.appOpenAdUnitId!));
        }
      },
      (shown) {
        if (shown) {
          _lastAppOpenTime = DateTime.now();
          emit(AdsShowSuccess(type: AdType.appOpen, config: _currentConfig));
          // Reload after show
          if (_currentConfig?.appOpenAdUnitId != null) {
            add(AdsLoadAppOpen(adUnitId: _currentConfig!.appOpenAdUnitId!));
          }
        }
      },
    );
  }

  Future<void> _onLoadNative(
    AdsLoadNative event,
    Emitter<AdsState> emit,
  ) async {
    final now = DateTime.now();
    if (_lastNativeTime != null &&
        now.difference(_lastNativeTime!).inSeconds <
            (_currentConfig?.minNativeInterval ?? 0)) {
      return;
    }

    final result = await adsRepository.loadNative(event.adUnitId);
    if (result.isLeft()) {
      result.fold(
        (failure) =>
            emit(AdsError(message: failure.message, config: _currentConfig)),
        (_) {},
      );
    } else {
      _lastNativeTime = DateTime.now();
      final ready = await _checkReadyStatus();
      if (!emit.isDone) emit(ready);
    }
  }

  Future<AdsReady> _checkReadyStatus() async {
    final interstitial = await adsRepository.isInterstitialReady();
    final rewarded = await adsRepository.isRewardedReady();
    final appOpen = await adsRepository.isAppOpenReady();
    final native = await adsRepository.isNativeReady();

    return AdsReady(
      isInterstitialReady: interstitial.getOrElse(() => false),
      isRewardedReady: rewarded.getOrElse(() => false),
      isAppOpenReady: appOpen.getOrElse(() => false),
      isNativeReady: native.getOrElse(() => false),
      config: _currentConfig,
    );
  }
}
