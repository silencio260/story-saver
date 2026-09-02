import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../../../../config/ad_unit_ids.dart';
import '../bloc/ads_bloc/ads_bloc.dart';
import '../bloc/iap_bloc/iap_bloc.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSubscription());
  }

  void _syncSubscription() {
    if (!mounted) return;
    final iap = context.read<IapBloc>().state;
    if (iap.isPremium) {
      _disposeAd();
    } else if (iap.status == IapViewStatus.ready) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (_bannerAd != null || _isLoading || AdUnitIds.banner.isEmpty) return;
    _isLoading = true;
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (!mounted ||
              context.read<IapBloc>().state.isPremium ||
              _bannerAd != loadedAd) {
            unawaited(loadedAd.dispose());
            return;
          }
          setState(() {
            _isLoading = false;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          unawaited(failedAd.dispose());
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoading = false;
            _isLoaded = false;
          });
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          if (!mounted) return;
          context.read<AnalyticsBloc>().add(
            AnalyticsEventLogged(
              AnalyticsEventEntity(
                name: 'ad_impression',
                parameters: <String, Object>{
                  'ad_unit_id': ad.adUnitId,
                  'ad_format': 'banner',
                  'value_micros': valueMicros,
                  'currency': currencyCode,
                },
              ),
            ),
          );
        },
      ),
    );
    _bannerAd = ad;
    unawaited(ad.load());
  }

  void _disposeAd() {
    final ad = _bannerAd;
    if (ad != null) unawaited(ad.dispose());
    _bannerAd = null;
    _isLoading = false;
    if (_isLoaded && mounted) {
      setState(() => _isLoaded = false);
    } else {
      _isLoaded = false;
    }
  }

  @override
  void dispose() {
    final ad = _bannerAd;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<IapBloc, IapState>(
        listenWhen:
            (previous, current) =>
                previous.isPremium != current.isPremium ||
                previous.status != current.status,
        listener: (context, state) => _syncSubscription(),
      ),
      BlocListener<AdsBloc, AdsState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == AdsViewStatus.disabled) {
            _disposeAd();
          } else if (state.status == AdsViewStatus.ready) {
            _syncSubscription();
          }
        },
      ),
    ],
    child:
        !_isLoaded || _bannerAd == null
            ? const SizedBox.shrink()
            : SafeArea(
              top: false,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
  );
}
