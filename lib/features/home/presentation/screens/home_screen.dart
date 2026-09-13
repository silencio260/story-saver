import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_ads_appodeal_native/genrevibes_ads_appodeal_native.dart';
import 'package:genrevibes_developer_access/genrevibes_developer_access.dart';
import 'package:genrevibes_exit_prompt/genrevibes_exit_prompt.dart';
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../config/routes_manager.dart';
import '../../../../container_injector.dart';
import '../../../../core/utils/legacy_custom_colors.dart';
import '../../../analytics/data/services/analytics_service.dart';
import '../../../monetization/data/services/subscription_service.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../../../monetization/presentation/widgets/native_ad_slot.dart';
import '../../../monetization/presentation/widgets/legacy/premium_upgrade_modal.dart';
import '../../../navigation/presentation/bloc/navigation_bloc/navigation_bloc.dart';
import '../../../permissions/presentation/bloc/permissions_bloc/permissions_bloc.dart';
import '../../../saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import '../../../saved_media/presentation/screens/saved_media_screen.dart';
import '../../../saved_media/presentation/services/legacy/batch_download_service.dart';
import '../../../settings/presentation/services/rating_prompt.dart';
import '../../../statuses/domain/entities/status_media.dart';
import '../../../statuses/presentation/bloc/status_bloc/status_bloc.dart';
import '../../../statuses/presentation/widgets/status_grid.dart';
import '../l10n/home_strings.dart';
import '../widgets/home_exit_prompt.dart';

/// The native ad under the status grid: the small card at normal size, without
/// media, on a light card that matches the grid, with the app color on its
/// button.
const AppodealNativeAdStyle _homeAdStyle = AppodealNativeAdStyle(
  layout: AppodealNativeAdLayout.small,
  backgroundColor: Color(0xFFF1F3F5),
  titleColor: Color(0xFF1F1F1F),
  bodyColor: Color(0xFF3C4043),
  callToActionColor: Color(CustomColors.AppBarColor),
  attributionColor: Color(CustomColors.AppBarColor),
  cornerRadius: 12,
  callToActionCornerRadius: 22,
  padding: 10,
  spacing: 6,
  iconSize: 44,
  callToActionHeight: 44,
  titleFontSize: 15,
  bodyFontSize: 13,
  callToActionFontSize: 16,
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<Widget> _pages = <Widget>[
    StatusGrid(type: StatusMediaType.image),
    StatusGrid(type: StatusMediaType.video),
    SavedMediaScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _pages.length,
      initialIndex: context.read<NavigationBloc>().state.currentIndex,
      vsync: this,
    )..addListener(_onTabChanged);

    context.read<StatusBloc>().add(
      const StatusBusinessModeRequested(reloadStatuses: true),
    );
    context.read<PermissionsBloc>().add(
      const PermissionsCheckRequested(isBusinessMode: false),
    );
    context.read<SavedMediaBloc>().add(const SavedMediaLoadRequested());
    // No interstitial on opening: the splash screen's ad is the launch ad, and
    // an interstitial straight after it is one ad on top of another.
    unawaited(_preloadExitAd());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && SubscriptionManager().hasReachedFirstStatus) {
        RatingPrompt.showIfEligible(context);
      }
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    final navigation = context.read<NavigationBloc>();
    if (navigation.state.currentIndex == _tabController.index) return;
    navigation.add(NavigationTabSelected(_tabController.index));
    if (_tabController.index == 2) {
      // A save can grant gallery access while the status tab is visible.
      context.read<PermissionsBloc>().add(
        PermissionsCheckRequested(
          isBusinessMode: context.read<StatusBloc>().state.isBusinessMode,
        ),
      );
    }
  }

  /// Loads the exit prompt's native ad before Back is pressed, so the prompt
  /// opens with its ad rather than the placeholder.
  Future<void> _preloadExitAd() async {
    final style =
        ExitPromptStyle.tryParse(
          sl<RemoteConfigCoordinator>().current.read(
            ExitPromptPolicyKeys.style,
          ),
        ) ??
        ExitPromptStyle.featuresSheet;
    // Only ad_sheet and ad_dialog carry an ad here; see HomeExitPrompt.
    if (!style.needsAd ||
        !sl<DeveloperAdSwitches>().allows(AdFormat.native)) {
      return;
    }
    await sl<GenRevibesStarterKit>().deferredStartupComplete;
    final access = SubscriptionManager();
    await access.initialize();
    if (!mounted || !access.adsAllowed) return;
    unawaited(sl<AdProvider>().load(AppPlacements.exitNative));
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<StatusBloc, StatusState>(
        listenWhen:
            (previous, current) =>
                previous.isBusinessMode != current.isBusinessMode,
        listener:
            (context, state) => context.read<PermissionsBloc>().add(
              PermissionsCheckRequested(isBusinessMode: state.isBusinessMode),
            ),
      ),
      BlocListener<PermissionsBloc, PermissionsState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, permissions) {
          final isBusinessMode =
              context.read<StatusBloc>().state.isBusinessMode;
          if (permissions.status == PermissionViewStatus.ready &&
              permissions.hasStatusFolderPermission(
                isBusinessMode: isBusinessMode,
              )) {
            context.read<StatusBloc>().add(const StatusLoadRequested());
          }
          if (permissions.hasStoragePermission &&
              context.read<SavedMediaBloc>().state.items.isEmpty) {
            context.read<SavedMediaBloc>().add(const SavedMediaLoadRequested());
          }
        },
      ),
      BlocListener<IapBloc, IapState>(
        listenWhen:
            (previous, current) => previous.isPremium != current.isPremium,
        listener: (context, state) {
          final statusState = context.read<StatusBloc>().state;
          if (!state.isPremium && statusState.isBusinessMode) {
            context.read<StatusBloc>().add(
              const StatusBusinessModeRequested(
                enabled: false,
                reloadStatuses: true,
              ),
            );
          }
        },
      ),
    ],
    // Back asks in the style remote config names; see HomeExitPrompt.
    child: ExitGuard(
      config:
          (context) => HomeExitPrompt.config(
            context,
            openGallery: () => _tabController.animateTo(2),
            openBusinessMode:
                () => _switchBusinessMode(
                  context.read<StatusBloc>().state.isBusinessMode,
                ),
          ),
      onShown:
          (style) => unawaited(
            AnalyticsService.track('exit_prompt_shown', <String, Object?>{
              'style': style.wireName,
            }),
          ),
      onResult:
          (result) => unawaited(
            AnalyticsService.track('exit_prompt_action', <String, Object?>{
              'style': result.style.wireName,
              'action': result.action.name,
              if (result.targetId case final target?) 'target': target,
            }),
          ),
      child: SafeArea(
        top: false,
        left: false,
        child: BlocBuilder<StatusBloc, StatusState>(
          buildWhen:
              (previous, current) =>
                  previous.isBusinessMode != current.isBusinessMode,
          builder:
              (context, statusState) => Scaffold(
                appBar: AppBar(
                  title: Text(
                    statusState.isBusinessMode
                        ? HomeStrings.businessAppTitle
                        : HomeStrings.appTitle,
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: const Color(CustomColors.AppBarColor),
                  foregroundColor: Colors.white,
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const <Tab>[
                      Tab(
                        child: Text(
                          HomeStrings.imageTab,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                      Tab(
                        child: Text(
                          HomeStrings.videoTab,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                      Tab(
                        child: Text(
                          HomeStrings.galleryTab,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    IconButton(
                      tooltip:
                          statusState.isBusinessMode
                              ? HomeStrings.personalMode
                              : HomeStrings.businessMode,
                      onPressed:
                          () => _switchBusinessMode(statusState.isBusinessMode),
                      icon: SvgPicture.asset(
                        statusState.isBusinessMode
                            ? 'assets/icons/whatsapp.svg'
                            : 'assets/icons/whatsapp-business.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: HomeStrings.settings,
                      onPressed:
                          () => Navigator.pushNamed(context, Routes.settings),
                      icon: const Icon(Icons.settings),
                    ),
                    BlocBuilder<IapBloc, IapState>(
                      buildWhen:
                          (previous, current) =>
                              previous.isPremium != current.isPremium,
                      builder:
                          (context, iapState) => IconButton(
                            tooltip:
                                iapState.isPremium
                                    ? HomeStrings.downloadAll
                                    : HomeStrings.unlockPremium,
                            onPressed:
                                iapState.isPremium
                                    ? _downloadAll
                                    : () => context.read<IapBloc>().add(
                                      const IapPaywallRequested(),
                                    ),
                            icon: Icon(
                              iapState.isPremium
                                  ? Icons.download
                                  : Icons.diamond_outlined,
                            ),
                          ),
                    ),
                  ],
                ),
                body: TabBarView(controller: _tabController, children: _pages),
                // A native ad under the grid instead of a banner. Its space is
                // kept, so the grid never jumps when it loads.
                bottomNavigationBar: const NativeAdSlot(
                  placement: AppPlacements.homeNative,
                  style: _homeAdStyle,
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                  preloadNext: true,
                ),
              ),
        ),
      ),
    ),
  );

  Future<void> _switchBusinessMode(bool isBusinessMode) async {
    if (!isBusinessMode && !context.read<IapBloc>().state.isPremium) {
      final shouldUpgrade = await showPremiumUpgradeModal(
        context,
        title: HomeStrings.unlockBusinessModeTitle,
        message: HomeStrings.unlockBusinessModeMessage,
      );
      if (shouldUpgrade == true && mounted) {
        context.read<IapBloc>().add(const IapPaywallRequested());
      }
      return;
    }

    if (!mounted) return;
    context.read<StatusBloc>().add(
      StatusBusinessModeRequested(
        enabled: !isBusinessMode,
        reloadStatuses: true,
      ),
    );
  }

  Future<void> _downloadAll() async {
    final statusState = context.read<StatusBloc>().state;
    await BatchDownloadService.downloadAll(
      context,
      statusState.images.map((media) => media.path).toList(),
      statusState.videos.map((media) => media.path).toList(),
    );
    if (mounted) {
      context.read<SavedMediaBloc>().add(const SavedMediaLoadRequested());
    }
  }
}
