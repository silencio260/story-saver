import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_admob/genrevibes_ads_admob.dart';
import 'package:genrevibes_ads_admob_ui/genrevibes_ads_admob_ui.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../container_injector.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../bloc/ads_bloc/ads_bloc.dart';
import '../bloc/iap_bloc/iap_bloc.dart';

/// The inline banner.
///
/// Loading, retrying, sizing and disposal are the kit widget's job now. This
/// file owns only the question the kit cannot answer: whether this app wants a
/// banner on screen at this moment. Previously it hand-rolled a `BannerAd`, its
/// listener, and the disposal races between "loaded" and "user just went
/// premium" — about a hundred lines that every app in the portfolio repeated.
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

  /// Consent and `MobileAds.initialize()` run after the first frame, and this
  /// widget builds on it. Requesting an ad before consent has been gathered is
  /// exactly what UMP exists to prevent, so the ad waits — the app does not.
  Future<void> _awaitStartup() async {
    await sl<GenRevibesStarterKit>().deferredStartupComplete;
    if (mounted) setState(() => _startupComplete = true);
  }

  /// This app's banner unit, or Google's sample unit on a device with developer
  /// access. A developer device in a store build must never render a live ad.
  AdMobAdUnit _servedUnit() {
    final unit = sl<AdMobAdUnit>();
    return sl<DeveloperAccessController>().current.servesTestAds
        ? unit.withTestUnitId()
        : unit;
  }

  void _onAdEvent(AdEvent event) {
    final revenue = event.revenue;
    if (event.type != AdEventType.paid || revenue == null) return;
    if (!mounted) return;
    context.read<AnalyticsBloc>().add(
      AnalyticsEventLogged(
        AnalyticsEventEntity(
          name: 'ad_impression',
          parameters: <String, Object>{
            'ad_unit_id': _servedUnit().adUnitId,
            'ad_format': event.placement.format.name,
            'value_micros': revenue.valueMicros,
            'currency': revenue.currencyCode,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final developerAccess = sl<DeveloperAccessController>();

    // Rebuilds when developer access changes, so the kit widget sees a
    // different unit and reloads: a phone recognised mid-session swaps its
    // live banner for a test one.
    return StreamBuilder<DeveloperAccess>(
      stream: developerAccess.changes,
      initialData: developerAccess.current,
      builder: (context, _) => BlocBuilder<IapBloc, IapState>(
      buildWhen: (previous, current) =>
          previous.isPremium != current.isPremium ||
          previous.status != current.status,
      builder: (context, iap) => BlocBuilder<AdsBloc, AdsState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, ads) {
          final unit = _servedUnit();
          // Every reason this app has for not showing a banner, in one
          // expression. The kit widget loads when this turns true and tears the
          // creative down when it turns false, so premium purchase mid-session
          // removes the ad without this file managing the race.
          final enabled = _startupComplete &&
              unit.adUnitId.isNotEmpty &&
              !iap.isPremium &&
              iap.status == IapViewStatus.ready &&
              ads.status != AdsViewStatus.disabled;

          if (!enabled) return const SizedBox.shrink();

          return SafeArea(
            top: false,
            child: AdMobBannerView(
              request: AdMobBannerRequest(unit: unit),
              enabled: enabled,
              onEvent: _onAdEvent,
            ),
          );
        },
      ),
      ),
    );
  }
}
