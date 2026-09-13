import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_appodeal/genrevibes_ads_appodeal.dart';
import 'package:genrevibes_ads_appodeal_native/genrevibes_ads_appodeal_native.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../container_injector.dart';
import '../../data/services/subscription_service.dart';
import '../bloc/ads_bloc/ads_bloc.dart';
import '../bloc/iap_bloc/iap_bloc.dart';

/// A native ad with its space kept, for a screen built around one.
///
/// The space is part of the screen for every user who can be shown ads, from
/// the first frame, with a quiet placeholder until the ad loads, so nothing
/// moves when it arrives. Premium users, and platforms where native ads do not
/// render, get no space at all.
///
/// The ad waits for what the banner waits for: deferred startup (consent),
/// known entitlements, access that allows ads, and ads not disabled. Native
/// events reach analytics through the attributed listener in bootstrap.
class NativeAdSlot extends StatefulWidget {
  const NativeAdSlot({
    required this.placement,
    required this.style,
    this.padding = EdgeInsets.zero,
    this.preloadNext = false,
    super.key,
  });

  /// A native placement configured on the Appodeal provider.
  final AdPlacement placement;

  /// The ad's look; its `resolvedHeight` is the space kept.
  final AppodealNativeAdStyle style;

  /// Around the ad, applied only when the slot takes space.
  final EdgeInsets padding;

  /// Whether to load the next ad as soon as this one shows, so the next slot
  /// built for this placement appears at once.
  final bool preloadNext;

  @override
  State<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends State<NativeAdSlot> {
  final SubscriptionManager _access = SubscriptionManager();
  final DeveloperAdSwitches _switches = sl<DeveloperAdSwitches>();
  StreamSubscription<void>? _switchChanges;
  bool _startupComplete = false;

  @override
  void initState() {
    super.initState();
    _access.addListener(_accessChanged);
    _switchChanges = _switches.changes.listen((_) => _accessChanged());
    unawaited(_awaitStartup());
  }

  @override
  void dispose() {
    _access.removeListener(_accessChanged);
    unawaited(_switchChanges?.cancel());
    super.dispose();
  }

  void _accessChanged() {
    if (mounted) setState(() {});
  }

  /// No ad is requested before consent has been gathered.
  Future<void> _awaitStartup() async {
    await sl<GenRevibesStarterKit>().deferredStartupComplete;
    if (mounted) setState(() => _startupComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final ads = sl<AdProvider>();
    if (ads is! AppodealAdProvider ||
        !AppodealNativeAds.instance.isSupported ||
        // Turned off on this developer phone in the Starter Kit Lab: no ad and
        // no space, so the screen shows as it would without one.
        !_switches.allows(widget.placement.format)) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<IapBloc, IapState>(
      buildWhen:
          (previous, current) =>
              previous.isPremium != current.isPremium ||
              previous.status != current.status,
      builder:
          (context, iap) => BlocBuilder<AdsBloc, AdsState>(
            buildWhen: (previous, current) => previous.status != current.status,
            builder: (context, adsState) {
              if (iap.isPremium) return const SizedBox.shrink();
              final enabled =
                  _startupComplete &&
                  _access.adsAllowed &&
                  iap.status == IapViewStatus.ready &&
                  adsState.status != AdsViewStatus.disabled;
              return SafeArea(
                top: false,
                child: Padding(
                  padding: widget.padding,
                  child: SizedBox(
                    height: widget.style.resolvedHeight,
                    child: AppodealNativeAdView(
                      provider: ads,
                      placement: widget.placement,
                      enabled: enabled,
                      style: widget.style,
                      placeholder: AppodealNativeAdPlaceholder(
                        style: widget.style,
                      ),
                      preloadNext: widget.preloadNext,
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
