import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../container_injector.dart';
import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/usecases/dispose_ads_usecase.dart';
import '../../../domain/usecases/load_interstitial_ad_usecase.dart';
import '../../../domain/usecases/show_interstitial_ad_usecase.dart';

/// Compatibility facade retaining the original `AdmobWrapper` API.
class AdmobWrapper extends ChangeNotifier {
  factory AdmobWrapper() => _instance;

  AdmobWrapper._internal();

  static final AdmobWrapper _instance = AdmobWrapper._internal();

  bool _isInterstitialAdReady = false;
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void resetInterstitialAdValues() {
    _isInterstitialAdReady = false;
    notifyListeners();
  }

  Future<void> loadInterstitialAd() async {
    final result = await sl<LoadInterstitialAdUseCase>()(NoParams.instance);
    _isInterstitialAdReady = result.isRight();
    notifyListeners();
  }

  Future<void> showInterstitialAd() async {
    final result = await sl<ShowInterstitialAdUseCase>()(NoParams.instance);
    result.fold((_) => null, (shown) => _isInterstitialAdReady = !shown);
    notifyListeners();
  }

  static void disposeAds() {
    if (!sl.isRegistered<DisposeAdsUseCase>()) return;
    unawaited(sl<DisposeAdsUseCase>()(NoParams.instance));
  }
}
