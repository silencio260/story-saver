import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_appodeal/genrevibes_ads_appodeal.dart';
import 'package:genrevibes_ads_appodeal_native/genrevibes_ads_appodeal_native.dart';
import 'package:genrevibes_exit_prompt/genrevibes_exit_prompt.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../config/routes_manager.dart';
import '../../../../container_injector.dart';
import '../../../../core/utils/legacy_custom_colors.dart';
import '../../../monetization/data/services/subscription_service.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../l10n/home_strings.dart';

/// The home screen's exit prompt, as remote config sets it.
///
/// `exit_prompt_style` picks the style and `exit_prompt_exit_button` the Exit
/// button, so both can be A/B tested in Firebase without a release. The
/// default, `features_sheet`, has no ad; only `ad_sheet` and `ad_dialog` carry
/// one, and they fall back to a plain confirmation for a premium user and
/// wherever native ads do not render.
abstract final class HomeExitPrompt {
  static const Color _accent = Color(CustomColors.AppBarColor);

  /// The native ad's look inside the prompt.
  static const AppodealNativeAdStyle adStyle = AppodealNativeAdStyle(
    backgroundColor: Color(0xFFF1F3F5),
    titleColor: Color(0xFF1F1F1F),
    bodyColor: Color(0xFF3C4043),
    callToActionColor: _accent,
    attributionColor: _accent,
    callToActionCornerRadius: 28,
    callToActionFontSize: 18,
    mediaHeight: 160,
  );

  /// Builds the prompt.
  ///
  /// [style] and [exitButton] override remote config, for the Lab's preview.
  /// Features that need the home screen appear only when it passes
  /// [openGallery] and [openBusinessMode].
  static ExitPromptConfig config(
    BuildContext context, {
    ExitPromptStyle? style,
    ExitButtonEmphasis? exitButton,
    VoidCallback? openGallery,
    VoidCallback? openBusinessMode,
  }) {
    final remote = sl<RemoteConfigCoordinator>().current;
    final isPremium = context.read<IapBloc>().state.isPremium;
    final provider = sl<AdProvider>();
    final adsAllowed =
        !isPremium &&
        SubscriptionManager().adsAllowed &&
        remote.read(AdsPolicyKeys.adsEnabled) &&
        AppodealNativeAds.instance.isSupported;

    final requested =
        style ??
        ExitPromptStyle.tryParse(remote.read(ExitPromptPolicyKeys.style)) ??
        ExitPromptStyle.featuresSheet;

    return ExitPromptConfig(
      style: requested,
      exitButton:
          exitButton ??
          ExitButtonEmphasis.tryParse(
            remote.read(ExitPromptPolicyKeys.exitButton),
          ) ??
          ExitButtonEmphasis.standard,
      // Only the styles built around an ad get one. The features sheet could
      // hold one, but it is the ad-free default: Google Play's ads policy
      // treats an ad triggered by exiting the app as disruptive.
      ad:
          requested.needsAd && adsAllowed && provider is AppodealAdProvider
              ? _ad(provider)
              : null,
      features: <ExitPromptFeature>[
        if (openGallery != null)
          ExitPromptFeature(
            id: 'saved_gallery',
            title: HomeStrings.featureGalleryTitle,
            subtitle: HomeStrings.featureGallerySubtitle,
            actionLabel: HomeStrings.tryNow,
            icon: const Icon(
              Icons.photo_library_outlined,
              color: _accent,
              size: 40,
            ),
            onSelected: (_) => openGallery(),
          ),
        if (openBusinessMode != null)
          ExitPromptFeature(
            id: 'business_mode',
            title: HomeStrings.featureBusinessTitle,
            subtitle: HomeStrings.featureBusinessSubtitle,
            actionLabel: HomeStrings.tryNow,
            icon: const Icon(
              Icons.business_center_outlined,
              color: _accent,
              size: 40,
            ),
            onSelected: (_) => openBusinessMode(),
          ),
        ExitPromptFeature(
          id: 'settings',
          title: HomeStrings.featureSettingsTitle,
          subtitle: HomeStrings.featureSettingsSubtitle,
          actionLabel: HomeStrings.tryNow,
          icon: const Icon(Icons.settings_outlined, color: _accent, size: 40),
          onSelected:
              (context) => Navigator.pushNamed(context, Routes.settings),
        ),
      ],
      offer:
          isPremium
              ? null
              : ExitPromptOffer(
                id: 'premium',
                title: HomeStrings.offerTitle,
                message: HomeStrings.offerMessage,
                actionLabel: HomeStrings.offerAction,
                artwork:
                    (_) => const Icon(
                      Icons.diamond_outlined,
                      size: 120,
                      color: _accent,
                    ),
                onAction:
                    (context) => context.read<IapBloc>().add(
                      const IapPaywallRequested(),
                    ),
              ),
      labels: const ExitPromptLabels(
        title: HomeStrings.exitPromptTitle,
        message: HomeStrings.exitPromptMessage,
        exit: HomeStrings.exit,
        cancel: HomeStrings.cancel,
        featuresTitle: HomeStrings.exitFeaturesTitle,
        doubleTapHint: HomeStrings.exitDoubleTapHint,
      ),
      theme: const ExitPromptTheme(accentColor: _accent),
    );
  }

  static ExitPromptAd _ad(AppodealAdProvider provider) => ExitPromptAd(
    height: adStyle.resolvedHeight,
    builder:
        (_) => AppodealNativeAdView(
          provider: provider,
          placement: AppPlacements.exitNative,
          enabled: true,
          style: adStyle,
          placeholder: const AppodealNativeAdPlaceholder(style: adStyle),
          // The next Back finds an ad already loaded.
          preloadNext: true,
        ),
  );
}
