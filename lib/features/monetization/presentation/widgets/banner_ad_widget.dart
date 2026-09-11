import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_appodeal/genrevibes_ads_appodeal.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../container_injector.dart';
import '../bloc/ads_bloc/ads_bloc.dart';
import '../bloc/iap_bloc/iap_bloc.dart';

/// The inline banner.
///
/// Loading, refreshing and test mode belong to Appodeal, behind the kit's
/// banner view. This file owns only the question the kit cannot answer:
/// whether this app wants a banner on screen at this moment. Banner revenue
/// reaches analytics from the provider's event stream, wired in bootstrap.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  /// Whether the deferred startup work that ads depend on has finished.
  bool _startupComplete = false;

  @override
  void initState() {
    super.initState();
    unawaited(_awaitStartup());
  }

  /// Consent and the ad SDK start after the first frame, and this widget builds
  /// on it. A banner must not be requested before consent has been gathered,
  /// so the banner waits — the app does not.
  Future<void> _awaitStartup() async {
    await sl<GenRevibesStarterKit>().deferredStartupComplete;
    if (mounted) setState(() => _startupComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final ads = sl<AdProvider>();
    // Inline banners are Appodeal's here; any other provider shows none.
    if (ads is! AppodealAdProvider) return const SizedBox.shrink();

    return BlocBuilder<IapBloc, IapState>(
      buildWhen: (previous, current) =>
          previous.isPremium != current.isPremium ||
          previous.status != current.status,
      builder: (context, iap) => BlocBuilder<AdsBloc, AdsState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, adsState) {
          // Every reason this app has for not showing a banner, in one
          // expression. The kit view adds the provider's own: not before the
          // SDK has initialized, and not while a test-mode change waits for a
          // relaunch — so a developer phone recognised mid-session never shows
          // a live banner.
          final enabled = _startupComplete &&
              !iap.isPremium &&
              iap.status == IapViewStatus.ready &&
              adsState.status != AdsViewStatus.disabled;

          if (!enabled) return const SizedBox.shrink();

          return SafeArea(
            top: false,
            child: AppodealBannerView(
              provider: ads,
              placement: AppPlacements.banner,
              enabled: enabled,
            ),
          );
        },
      ),
    );
  }
}
