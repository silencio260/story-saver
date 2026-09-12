import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_splash/genrevibes_splash.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../config/routes_manager.dart';
import '../../../../container_injector.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/legacy_custom_colors.dart';
import '../../../analytics/data/services/analytics_service.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../../../monetization/data/services/subscription_service.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../../../saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import '../bloc/splash_bloc/splash_bloc.dart';
import '../l10n/splash_strings.dart';

/// The launch screen, on the kit's `SplashFlow`.
///
/// A loading bar while the app decides where to go and the ad SDK starts,
/// then, when `splash_ad_format` names one and the user is not premium, that
/// full-screen ad, then onboarding or home. `splash_ad_max_wait_seconds`
/// bounds the wait, so an ad that does not fill never holds the user here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _accent = Color(CustomColors.AppBarColor);

  static const SplashLoadingStyle _style = SplashLoadingStyle(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFD7F0DE), Color(0xFFFFFFFF)],
    ),
    titleStyle: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: _accent,
    ),
    progressColor: _accent,
  );

  RemoteConfigSnapshot get _config => sl<RemoteConfigCoordinator>().current;

  @override
  void initState() {
    super.initState();
    context.read<SavedMediaBloc>().add(const SavedMediaLoadRequested());
    context.read<AnalyticsBloc>().add(
      const AnalyticsEventLogged(
        AnalyticsEventEntity(name: 'goto_splash_screen'),
      ),
    );
    context.read<SplashBloc>().add(const SplashStarted());
  }

  /// Where to go next is known once the bloc answers.
  Future<void> _prepare() async {
    final bloc = context.read<SplashBloc>();
    if (bloc.state.destination != SplashDestination.pending) return;
    await bloc.stream.firstWhere(
      (state) => state.destination != SplashDestination.pending,
    );
  }

  /// The ad for this launch, or null for none.
  Future<SplashAdRequest?> _resolveAd() async {
    final firstLaunch =
        context.read<SplashBloc>().state.destination ==
        SplashDestination.onboarding;
    final iap = context.read<IapBloc>();

    final format = SplashAdPolicyKeys.formatOf(_config);
    if (format == null || !_config.read(AdsPolicyKeys.adsEnabled)) return null;
    if (firstLaunch && !_config.read(SplashAdPolicyKeys.onFirstLaunch)) {
      return null;
    }
    final providerId = _config.read(SplashAdPolicyKeys.provider).trim();
    final placement = AppPlacements.splashFor(format);
    if (placement == null) return null;
    final request = sl<SplashAdRegistry>().resolve(
      providerId: providerId,
      placement: placement,
      canRequest:
          () =>
              mounted &&
              !iap.state.isPremium &&
              SubscriptionManager().adsAllowed &&
              _config.read(AdsPolicyKeys.adsEnabled) &&
              SplashAdPolicyKeys.formatOf(_config) == format &&
              _config.read(SplashAdPolicyKeys.provider).trim() == providerId &&
              (!firstLaunch || _config.read(SplashAdPolicyKeys.onFirstLaunch)),
    );
    if (request == null) return null;

    // Consent and the ad SDK start after the first frame, and an ad may not
    // be requested before consent has been gathered.
    await sl<GenRevibesStarterKit>().deferredStartupComplete;
    // A premium user must never see it, so wait until entitlements are known.
    if (!_entitlementsKnown(iap.state)) {
      await iap.stream.firstWhere(_entitlementsKnown);
    }
    final access = SubscriptionManager();
    await access.initialize();
    if (iap.state.isPremium || !access.adsAllowed) return null;
    return request.canRequest?.call() == false ? null : request;
  }

  static bool _entitlementsKnown(IapState state) =>
      state.status == IapViewStatus.ready ||
      state.status == IapViewStatus.failure;

  void _finished(SplashOutcome outcome) {
    unawaited(
      AnalyticsService.track('splash_ad_result', <String, Object?>{
        'status': outcome.adStatus.name,
        if (outcome.placement case final placement?) 'placement': placement.id,
        'wait_ms': outcome.elapsed.inMilliseconds,
      }),
    );
    unawaited(_leave());
  }

  Future<void> _leave() async {
    final bloc = context.read<SplashBloc>();
    final analytics = context.read<AnalyticsBloc>();
    var state = bloc.state;
    if (state.destination == SplashDestination.pending) {
      state = await bloc.stream.firstWhere(
        (next) => next.destination != SplashDestination.pending,
      );
    }
    if (!mounted) return;
    analytics.add(
      const AnalyticsEventLogged(AnalyticsEventEntity(name: 'goto_home_page')),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      state.destination == SplashDestination.home
          ? Routes.home
          : Routes.onboarding,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SplashFlow(
      maxWait: Duration(
        seconds: _config.read(SplashAdPolicyKeys.maxWaitSeconds),
      ),
      minDuration: const Duration(seconds: 2),
      prepare: _prepare,
      resolveAd: _resolveAd,
      adExpected:
          _config.read(AdsPolicyKeys.adsEnabled) &&
          SplashAdPolicyKeys.formatOf(_config) != null &&
          !context.read<IapBloc>().state.isPremium,
      onFinished: _finished,
      builder:
          (context, progress) => SplashLoadingView(
            progress: progress,
            logo: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/images/app-logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            title: AppStrings.appName,
            style: _style,
            labels: const SplashLabels(
              loading: SplashStrings.loading,
              adDisclosure: SplashStrings.adDisclosure,
            ),
          ),
    ),
  );
}
