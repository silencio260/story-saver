import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_appodeal/genrevibes_ads_appodeal.dart';
import 'package:genrevibes_ads_appodeal_native/genrevibes_ads_appodeal_native.dart';
import 'package:genrevibes_onboarding/genrevibes_onboarding.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../config/routes_manager.dart';
import '../../../../container_injector.dart';
import '../../../../core/utils/legacy_custom_colors.dart';
import '../../../monetization/data/services/subscription_service.dart';
import '../../../monetization/presentation/bloc/ads_bloc/ads_bloc.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../bloc/onboarding_bloc/onboarding_bloc.dart';
import '../l10n/onboarding_strings.dart';

/// First-launch onboarding, on the kit's `OnboardingFlow`.
///
/// Every page is its own complete screen, swiping in as a unit. When
/// `onboarding_ads_enabled` permits it and the user is not premium, the first
/// and third screens are built around a native ad, with dots and next above
/// it, and the second is a full-screen page. Otherwise every screen is full
/// screen, with skip, dots and next in a row. Either way, finishing opens the
/// paywall, then records completion, and the listener below goes home.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.forceShow = false, super.key});

  final bool forceShow;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _accent = Color(CustomColors.AppBarColor);

  /// The three pages.
  ///
  /// In the ad presentation every page is an edge-to-edge screen, its artwork
  /// across the top taking the height the rest leaves, and they alternate: the
  /// first and third are built around a native ad, and the second is a
  /// full-screen page with no ad. Each ad screen has its own ad.
  static List<OnboardingPage> _pagesFor({required bool withAds}) {
    OnboardingPage page(
      String title,
      String description,
      String image, {
      bool showAd = true,
    }) => OnboardingPage(
      title: title,
      description: description,
      showAd: showAd,
      layout:
          withAds
              ? OnboardingScreenLayout.edgeToEdge
              : OnboardingScreenLayout.standard,
      artwork:
          withAds
              ? (_) => _HeroArtwork(image: image)
              : (_) => Image.asset(image, fit: BoxFit.contain),
    );

    return <OnboardingPage>[
      page(
        OnboardingStrings.firstTitle,
        OnboardingStrings.firstDescription,
        'assets/images/onboarding_1.png',
      ),
      page(
        OnboardingStrings.secondTitle,
        OnboardingStrings.secondDescription,
        'assets/images/onboarding_2.png',
        showAd: false,
      ),
      page(
        OnboardingStrings.thirdTitle,
        OnboardingStrings.thirdDescription,
        'assets/images/onboarding_3.png',
      ),
    ];
  }

  /// The ad card, as part of the screen around it: a light card, a dark
  /// headline, and the app color on a pill-shaped call to action.
  static const AppodealNativeAdStyle _adStyle = AppodealNativeAdStyle(
    backgroundColor: Color(0xFFF1F3F5),
    titleColor: Color(0xFF1F1F1F),
    bodyColor: Color(0xFF3C4043),
    callToActionColor: _accent,
    attributionColor: _accent,
    callToActionCornerRadius: 28,
    callToActionFontSize: 18,
  );

  /// Opens the paywall and waits for it, for at most five seconds, as before
  /// the kit: onboarding goes on when the store does not answer.
  static final OnboardingAction _openPaywall = OnboardingAction(
    (context) async {
      final iapBloc = context.read<IapBloc>();
      final finished = iapBloc.stream.firstWhere(
        (state) =>
            state.status == IapViewStatus.ready ||
            state.status == IapViewStatus.failure,
      );
      iapBloc.add(const IapPaywallRequested());
      await finished;
    },
    name: 'paywall',
    continueOnError: true,
    timeout: const Duration(seconds: 5),
  );

  /// Records completion through the bloc, which also reports it. The listener
  /// in [build] goes home once it succeeds; a failure keeps the user here.
  static final OnboardingAction _completeOnboarding = OnboardingAction(
    (context) async {
      final bloc = context.read<OnboardingBloc>();
      final outcome = bloc.stream.firstWhere(
        (state) =>
            state.status == OnboardingViewStatus.completed ||
            state.status == OnboardingViewStatus.failure,
      );
      bloc.add(const OnboardingCompleted());
      final state = await outcome;
      if (state.status == OnboardingViewStatus.failure) {
        throw OnboardingActionException(
          state.message ?? 'Onboarding could not be saved.',
        );
      }
    },
    name: 'complete_onboarding',
  );

  final SubscriptionManager _access = SubscriptionManager();
  bool _startupComplete = false;

  @override
  void initState() {
    super.initState();
    _access.addListener(_accessChanged);
    unawaited(_awaitStartup());
  }

  @override
  void dispose() {
    _access.removeListener(_accessChanged);
    super.dispose();
  }

  void _accessChanged() {
    if (mounted) setState(() {});
  }

  /// Consent and the ad SDK start after the first frame. The ad waits for
  /// them; onboarding does not.
  Future<void> _awaitStartup() async {
    await sl<GenRevibesStarterKit>().deferredStartupComplete;
    if (mounted) setState(() => _startupComplete = true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state.status == OnboardingViewStatus.completed) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (_) => false,
            );
          } else if (state.status == OnboardingViewStatus.failure &&
              state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        child: BlocBuilder<IapBloc, IapState>(
          buildWhen:
              (previous, current) =>
                  previous.isPremium != current.isPremium ||
                  previous.status != current.status,
          builder:
              (context, iap) => BlocBuilder<AdsBloc, AdsState>(
                buildWhen:
                    (previous, current) => previous.status != current.status,
                builder: (context, adsState) {
                  final ads = sl<AdProvider>();
                  // The remote switch, premium, and whether native ads render
                  // on this platform at all pick the presentation. An ad
                  // screen keeps its ad's space, so it is only chosen where an
                  // ad can fill it.
                  final withAds =
                      sl<RemoteConfigCoordinator>().current.read(
                        OnboardingPolicyKeys.adsEnabled,
                      ) &&
                      !iap.isPremium &&
                      AppodealNativeAds.instance.isSupported;
                  // Every reason this app has for not showing an ad right
                  // now, the same ones the banner uses. The kit view adds the
                  // provider's own: initialization, consent and test mode.
                  final adAllowed =
                      _startupComplete &&
                      _access.adsAllowed &&
                      !iap.isPremium &&
                      iap.status == IapViewStatus.ready &&
                      adsState.status != AdsViewStatus.disabled;
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: OnboardingFlow(
                      pages: _pagesFor(withAds: withAds),
                      controlsLayout:
                          withAds
                              ? OnboardingControlsLayout.stacked
                              : OnboardingControlsLayout.row,
                      skipBehavior:
                          withAds
                              ? OnboardingSkipBehavior.hidden
                              : OnboardingSkipBehavior.jumpToLastPage,
                      adSlot:
                          withAds && ads is AppodealAdProvider
                              ? OnboardingAdSlot(
                                // The ad's space is part of every ad screen
                                // from its first frame, so nothing moves when
                                // the ad loads.
                                reservedHeight: _adStyle.resolvedHeight,
                                builder:
                                    (context, _) => AppodealNativeAdView(
                                      provider: ads,
                                      placement: AppPlacements.onboardingNative,
                                      enabled: adAllowed,
                                      style: _adStyle,
                                      placeholder:
                                          const AppodealNativeAdPlaceholder(
                                            style: _adStyle,
                                          ),
                                      // The full-screen page between the two
                                      // ad screens is when the next ad loads.
                                      preloadNext: true,
                                    ),
                              )
                              : null,
                      labels: const OnboardingLabels(
                        next: OnboardingStrings.next,
                        skip: OnboardingStrings.skip,
                        finish: OnboardingStrings.start,
                      ),
                      style: _style(withAds: withAds),
                      onPageChanged:
                          (index) => context.read<OnboardingBloc>().add(
                            OnboardingPageChanged(index),
                          ),
                      finishActions: <OnboardingAction>[
                        _openPaywall,
                        _completeOnboarding,
                      ],
                    ),
                  );
                },
              ),
        ),
      );

  static OnboardingFlowStyle _style({required bool withAds}) =>
      OnboardingFlowStyle(
        backgroundColor: Colors.white,
        titleStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: withAds ? _accent : Colors.black87,
          height: 1.2,
        ),
        descriptionStyle: const TextStyle(
          fontSize: 16,
          color: Colors.grey,
          height: 1.5,
        ),
        activeIndicatorColor: _accent,
        inactiveIndicatorColor: Colors.black12,
        buttonStyle: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        textButtonStyle: TextButton.styleFrom(
          foregroundColor: _accent,
          textStyle: TextStyle(
            fontSize: withAds ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        skipButtonStyle: TextButton.styleFrom(
          foregroundColor: Colors.grey,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        pagePadding: const EdgeInsets.all(20),
        controlsPadding:
            // On an ad screen, a clear gap under Next: an ad right against the
            // button a user is tapping draws accidental clicks, which networks
            // penalize.
            withAds
                ? const EdgeInsets.fromLTRB(20, 0, 20, 16)
                : const EdgeInsets.fromLTRB(20, 0, 20, 50),
        // A screen without an ad puts its controls where a full-screen page
        // would, not tight above an ad that is not there.
        adFreeControlsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
        textSpacing: 15,
        // The artwork melts into the page above the title instead of ending on
        // a hard line.
        artworkFadeHeight: withAds ? 40 : 0,
      );
}

/// Artwork across the top of an edge-to-edge onboarding screen.
///
/// The illustrations are square with transparent backgrounds, so they sit
/// uncropped on a soft green that fills the artwork area edge to edge and runs
/// under the status bar. Tall, full-bleed artwork would use `BoxFit.cover`
/// instead.
class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFD7F0DE), Color(0xFFF3FAF5)],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Image.asset(image, fit: BoxFit.contain),
      ),
    ),
  );
}
