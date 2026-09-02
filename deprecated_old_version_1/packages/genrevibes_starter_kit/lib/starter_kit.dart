import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'features/ads/ads_injector.dart';
import 'features/ads/presentation/bloc/ads_bloc.dart';
import 'features/ads/domain/services/ad_suppression_manager.dart';
import 'features/analytics/analytics_injector.dart';
import 'features/analytics/data/datasources/posthog_remote_data_source.dart';
import 'features/analytics/data/datasources/mixpanel_remote_data_source.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/analytics/presentation/bloc/analytics_event.dart';
import 'features/analytics/domain/repositories/analytics_repository.dart';
import 'features/iap/iap_injector.dart';
import 'features/iap/presentation/bloc/iap_bloc.dart';
import 'features/iap/domain/services/subscription_manager.dart';
import 'features/analytics/domain/services/analytics_service.dart';
import 'features/analytics/domain/services/retention_tracker.dart';
import 'features/analytics/domain/services/user_targeting_manager.dart';
import 'features/ads/domain/repositories/ads_repository.dart';
import 'features/onboarding/domain/models/onboarding_page_model.dart';
import 'features/onboarding/presentation/onboarding_view.dart';
import 'features/services/services.dart';
import 'features/settings/domain/models/settings_models.dart';
import 'features/settings/presentation/settings_view.dart';
import 'features/navigation/domain/models/double_tap_config.dart';
import 'features/navigation/presentation/widgets/double_tap_to_exit_widget.dart';
import 'features/ads/presentation/widgets/banner_ad_widget.dart';
import 'features/ads/presentation/widgets/native_ad_widget.dart';
import 'features/analytics/presentation/widgets/posthog_wrapper.dart';
import 'features/analytics/presentation/widgets/mixpanel_wrapper.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/starter_log.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

export 'core/utils/starter_log.dart';
export 'core/error/failure.dart';
export 'features/ads/ads.dart';
export 'features/iap/presentation/widgets/premium_upgrade_modal.dart';
export 'features/analytics/domain/services/analytics_service.dart';
export 'features/analytics/data/datasources/mixpanel_remote_data_source.dart';
export 'features/analytics/presentation/bloc/analytics_bloc.dart';
export 'features/analytics/presentation/widgets/posthog_wrapper.dart';
export 'features/analytics/presentation/widgets/mixpanel_wrapper.dart';
export 'features/onboarding/presentation/onboarding_view.dart';
export 'features/onboarding/domain/models/onboarding_page_model.dart';

import 'features/auth/auth_injector.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/database/database_injector.dart';
import 'features/database/domain/repositories/user_profile_repository.dart';
import 'features/iap/domain/repositories/iap_repository.dart';

/// The Facade for the Starter Kit Plugin
///
/// Initializes all dependencies and provides access to Blocs and UI Templates.
class StarterKit {
  static final GetIt _sl = GetIt.asNewInstance();

  /// Access the internal Service Locator if needed
  static GetIt get sl => _sl;

  static String? _supportEmail;

  /// The support email supplied at [initialize], if any. Useful for
  /// "Contact support" links in host apps. `null` when not provided.
  static String? get supportEmail => _supportEmail;

  /// Initialize the Starter Kit
  static Future<void> initialize({
    String? supportEmail,
    String? feedbackNestApiKey,
    AuthRepository? authRepository,
    UserProfileRepository? userProfileRepository,
    IapRepository? iapRepository,
    AdsRepository? adsRepository,
    AnalyticsRepository? analyticsRepository,
    RemoteConfigRepository? remoteConfigRepository,
    AppRatingRepository? appRatingRepository,
    GdprRepository? gdprRepository,
    PushNotificationsRepository? pushNotificationsRepository,
    FeedbackRepository? feedbackRepository,
    PostHogRemoteDataSource? postHogDataSource,
    MixpanelRemoteDataSource? mixpanelDataSource,
    String? analyticsUserId,
    String? mixpanelToken,
    String? mixpanelDistinctId,
    bool autoTrackAppOpen = true,
    bool mirrorFirebaseFirstOpenToMixpanel = true,
    LocalStorage? retentionStorage,
    bool mixpanelMaskAllText = true,
    bool mixpanelMaskAllImages = true,
    double mixpanelSessionsPercent = 100.0,
    bool mixpanelWifiOnly = false,
    bool debugLogging = kDebugMode,
  }) async {
    // Store config for host-app accessors
    _supportEmail = supportEmail;

    // Initialize Logger
    StarterLog.init(enableLogging: debugLogging);
    StarterLog.d('StarterKit Initializing...', tag: 'CORE');

    // Analytics & PostHog
    initAnalyticsFeature(
      _sl,
      analyticsRepository: analyticsRepository,
      postHogRemoteDataSource: postHogDataSource,
      mixpanelRemoteDataSource: mixpanelDataSource,
    );

    // Database (User Profile)
    initDatabase(
      sl: _sl,
      userProfileRepository: userProfileRepository,
    );

    // Auth
    initAuth(
      sl: _sl,
      authRepository: authRepository,
    );

    // IAP
    initIapFeature(_sl, iapRepository: iapRepository);

    // Ads
    initAdsFeature(
      _sl,
      adsRepository: adsRepository,
      onPaidEvent: (revenueEvent) {
        _sl<AnalyticsBloc>().add(AnalyticsLogAdRevenue(revenueEvent));
      },
    );

    // Services (Support, Feedback, etc.)
    initServicesFeature(
      _sl,
      remoteConfigRepository: remoteConfigRepository,
      appRatingRepository: appRatingRepository,
      gdprRepository: gdprRepository,
      pushNotificationsRepository: pushNotificationsRepository,
      feedbackRepository: feedbackRepository,
      feedbackNestApiKey: feedbackNestApiKey,
    );

    // Link Subscription status to Ad suppression
    SubscriptionManager.instance.addListener(() {
      if (SubscriptionManager.instance.isPremium) {
        AdSuppressionManager.instance.suppressAds('premium');
      } else {
        AdSuppressionManager.instance.enableAds('premium');
      }
    });

    // Handle initial state
    if (SubscriptionManager.instance.isPremium) {
      AdSuppressionManager.instance.suppressAds('premium');
    }

    await _initializeStartupAnalytics(
      analyticsUserId: analyticsUserId,
      mixpanelToken: mixpanelToken,
      mixpanelDistinctId: mixpanelDistinctId,
      autoTrackAppOpen: autoTrackAppOpen,
      mirrorFirebaseFirstOpenToMixpanel: mirrorFirebaseFirstOpenToMixpanel,
      retentionStorage: retentionStorage,
      mixpanelMaskAllText: mixpanelMaskAllText,
      mixpanelMaskAllImages: mixpanelMaskAllImages,
      mixpanelSessionsPercent: mixpanelSessionsPercent,
      mixpanelWifiOnly: mixpanelWifiOnly,
    );
  }

  static Future<void> _initializeStartupAnalytics({
    required String? analyticsUserId,
    required String? mixpanelToken,
    required String? mixpanelDistinctId,
    required bool autoTrackAppOpen,
    required bool mirrorFirebaseFirstOpenToMixpanel,
    required LocalStorage? retentionStorage,
    required bool mixpanelMaskAllText,
    required bool mixpanelMaskAllImages,
    required double mixpanelSessionsPercent,
    required bool mixpanelWifiOnly,
  }) async {
    final mixpanelId = mixpanelDistinctId ?? analyticsUserId;
    if (mixpanelToken != null &&
        mixpanelToken.isNotEmpty &&
        mixpanelId != null &&
        mixpanelId.isNotEmpty) {
      await mixpanel?.initialize(
        token: mixpanelToken,
        distinctId: mixpanelId,
        maskAllText: mixpanelMaskAllText,
        maskAllImages: mixpanelMaskAllImages,
        sessionsPercent: mixpanelSessionsPercent,
        wifiOnly: mixpanelWifiOnly,
      );
    }

    if (analyticsUserId != null && analyticsUserId.isNotEmpty) {
      await analytics.setUserId(analyticsUserId);
    }

    if (!retentionTracker.hasStorage) {
      retentionTracker.init(retentionStorage ?? SharedPreferencesStorage());
    }

    if (!autoTrackAppOpen) return;

    await analytics.logEvent('app_open');
    await retentionTracker.trackAppOpen(analytics);

    // Log the user segment and attach the resume-driven session observer.
    // The app open was already tracked above, so use startSegmentTracking to
    // avoid double-counting it.
    await UserTargetingManager.startSegmentTracking(analytics);

    if (mirrorFirebaseFirstOpenToMixpanel &&
        retentionTracker.getTotalAppOpens() == 1) {
      await mixpanel?.capture(
        eventName: 'first_open',
        properties: {
          'source': 'retention_tracker',
          'mirrors_firebase_automatic_event': true,
        },
      );
    }
  }

  // --- Bloc Accessors ---

  static IapBloc get iapBloc => _sl<IapBloc>();
  static AdsBloc get adsBloc => _sl<AdsBloc>();
  static AnalyticsBloc get analyticsBloc => _sl<AnalyticsBloc>();

  /// Access the Analytics Service for high-level event logging
  static AnalyticsService get analytics => AnalyticsService(analyticsBloc);

  /// Access the Subscription Manager for simple premium status checks
  static SubscriptionManager get subscriptionManager =>
      SubscriptionManager.instance;

  /// Access the Retention Tracker for engagement data
  static RetentionTracker get retentionTracker => RetentionTracker.instance;

  /// Access the User Targeting Manager for segmentation data
  static UserTargetingManager get userTargetingManager =>
      UserTargetingManager.instance;

  /// Access the Ads Repository directly
  static AdsRepository get adsRepository => _sl<AdsRepository>();

  /// Access PostHog directly if initialized
  static PostHogRemoteDataSource? get postHog {
    try {
      return _sl<PostHogRemoteDataSource>();
    } catch (_) {
      return null;
    }
  }

  /// Access Mixpanel directly if registered. Use for session-replay lifecycle
  /// control: `StarterKit.mixpanel?.stopReplay()` inside secure mini-apps and
  /// `startReplay()` on exit.
  static MixpanelRemoteDataSource? get mixpanel {
    try {
      return _sl<MixpanelRemoteDataSource>();
    } catch (_) {
      return null;
    }
  }

  // --- UI Template Builders ---

  /// Build a robust Onboarding Screen
  static Widget onboarding({
    required List<OnboardingPageModel> pages,
    OnboardingTemplateType template = OnboardingTemplateType.standard,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
    Function(int)? onPageChange,
    Color activeDotColor = Colors.blue,
    String nextText = 'Next',
    String completeText = 'Start',
    bool debugLog = false,
  }) {
    if (debugLog) {
      StarterLog.d(
        'Building Onboarding Screen',
        tag: 'UI',
        debugLog: true,
        values: {'Page Count': pages.length, 'Template': template.name},
      );
    }
    return OnboardingView(
      pages: pages,
      templateType: template,
      onComplete: onComplete,
      onSkip: onSkip,
      onPageChange: onPageChange,
      activeDotColor: activeDotColor,
      nextButtonText: nextText,
      completeButtonText: completeText,
    );
  }

  /// Build a robust Settings Screen
  static Widget settings({
    required List<SettingsSection> sections,
    SettingsTemplateType template = SettingsTemplateType.list,
    String title = 'Settings',
    Color? backgroundColor,
    bool debugLog = false,
  }) {
    if (debugLog) {
      StarterLog.d(
        'Building Settings Screen',
        tag: 'UI',
        debugLog: true,
        values: {'Sections': sections.length, 'Title': title},
      );
    }
    return SettingsView(
      sections: sections,
      templateType: template,
      pageTitle: title,
      backgroundColor: backgroundColor,
    );
  }

  // --- Widget Builders ---

  /// Build a Banner Ad Widget
  static Widget bannerAd({
    AdSize adSize = AdSize.banner,
    String? adUnitId,
    Color? backgroundColor,
    bool debugLog = false,
  }) {
    if (debugLog) {
      StarterLog.d(
        'Building Banner Ad',
        tag: 'ADS',
        debugLog: true,
        values: {
          'Size': adSize.toString(),
          'UnitID': adUnitId ?? 'config_default',
        },
      );
    }
    return BannerAdWidget(
      adSize: adSize,
      adUnitId: adUnitId,
      backgroundColor: backgroundColor,
    );
  }

  /// Build a Native Ad Widget
  static Widget nativeAd({
    String? adUnitId,
    NativeTemplateStyle? templateStyle,
    double? width,
    double? height,
    bool debugLog = false,
  }) {
    if (debugLog) {
      StarterLog.d(
        'Building Native Ad',
        tag: 'ADS',
        debugLog: true,
        values: {
          'UnitID': adUnitId ?? 'config_default',
          'Width': width ?? 'auto',
          'Height': height ?? 'auto',
        },
      );
    }
    return NativeAdWidget(
      adUnitId: adUnitId,
      templateStyle: templateStyle,
      width: width,
      height: height,
    );
  }

  /// Build a PostHog Wrapper
  static Widget postHogWrapper({
    required Widget child,
    required String apiKey,
    String host = 'https://app.posthog.com',
    bool captureLocalStorage = false,
    bool captureApplicationLifecycleEvents = true,
  }) {
    return PostHogWrapper(
      apiKey: apiKey,
      host: host,
      captureLocalStorage: captureLocalStorage,
      captureApplicationLifecycleEvents: captureApplicationLifecycleEvents,
      child: child,
    );
  }

  /// Build a Mixpanel Wrapper (events + session replay).
  ///
  /// Wrap the root (e.g. `MaterialApp`). Initializes Mixpanel with [token] and
  /// mounts session replay. [distinctId] should be the app's anonymous install
  /// UUID. Replay masks all text + images by default.
  static Widget mixpanelWrapper({
    required Widget child,
    required String token,
    required String distinctId,
    bool maskAllText = true,
    bool maskAllImages = true,
    double sessionsPercent = 100.0,
    bool wifiOnly = false,
    bool enableSessionReplay = true,
  }) {
    return MixpanelWrapper(
      token: token,
      distinctId: distinctId,
      maskAllText: maskAllText,
      maskAllImages: maskAllImages,
      sessionsPercent: sessionsPercent,
      wifiOnly: wifiOnly,
      enableSessionReplay: enableSessionReplay,
      child: child,
    );
  }

  /// Build a Double Tap to Exit wrapper widget
  ///
  /// Wraps a widget with double tap to exit functionality:
  /// - First back tap: Shows an exit confirmation dialog
  /// - Second back tap (within timeout): Exits the app
  ///
  /// All aspects of the dialog and snackbar are customizable through [config].
  static Widget doubleTapToExit({
    required Widget child,
    DoubleTapExitConfig? config,
    bool debugLog = false,
  }) {
    if (debugLog) {
      StarterLog.d(
        'Building Double Tap to Exit Wrapper',
        tag: 'UI',
        debugLog: true,
      );
    }
    return DoubleTapToExitWidget(
      config: config ?? const DoubleTapExitConfig(),
      child: child,
    );
  }
}
