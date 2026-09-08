import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routes_manager.dart';
import '../../../../bootstrap/app_runtime.dart';
import '../../../../container_injector.dart';
import '../../../../core/utils/development_mode_utils.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc/analytics_bloc.dart';
import '../../../monetization/presentation/bloc/iap_bloc/iap_bloc.dart';
import '../../../monetization/presentation/widgets/legacy/premium_upgrade_modal.dart';
import '../../../onboarding/presentation/bloc/onboarding_bloc/onboarding_bloc.dart';
import '../../../saved_media/presentation/bloc/saved_media_bloc/saved_media_bloc.dart';
import '../../../saved_media/presentation/services/legacy/share_to_app.dart';
import '../../../statuses/presentation/bloc/status_bloc/status_bloc.dart';
import '../bloc/settings_bloc/settings_bloc.dart';
import '../l10n/settings_strings.dart';
import '../services/legacy/app_rating_service.dart';
import '../../../developer/dev_tools_entry.dart';
import 'module_health_screen.dart';

import '../services/legacy/developer_options_service.dart';
import '../services/legacy/feedback_helper.dart';
import '../widgets/legacy/help_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _canvasColor = Color(0xff154734);
  static const String _devAutoSaveKey = 'is_dev_auto_save_test_mode';

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const SettingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: (context, state) {
          if (state.message != null) _showMessage(state.message!);
        },
      ),
      BlocListener<IapBloc, IapState>(
        listenWhen: (previous, current) => previous.message != current.message,
        listener: (context, state) {
          if (state.message != null) _showMessage(state.message!);
        },
      ),
    ],
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _canvasColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          SettingsStrings.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder:
            (context, settingsState) => BlocBuilder<IapBloc, IapState>(
              builder:
                  (context, iapState) => BlocBuilder<StatusBloc, StatusState>(
                    builder:
                        (context, statusState) => ListView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: MediaQuery.of(context).padding.bottom + 80,
                          ),
                          children: <Widget>[
                            _settingsItem(
                              icon:
                                  statusState.isBusinessMode
                                      ? Icons.person
                                      : Icons.business,
                              label:
                                  statusState.isBusinessMode
                                      ? SettingsStrings.personalStatus
                                      : SettingsStrings.businessMode,
                              onTap:
                                  () => _switchBusinessMode(
                                    statusState.isBusinessMode,
                                    iapState.isPremium,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.workspace_premium,
                              label: SettingsStrings.removeAds,
                              onTap: () {
                                _log('remove_ads_clicked');
                                context.read<IapBloc>().add(
                                  const IapPaywallRequested(),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.email_outlined,
                              label: SettingsStrings.support,
                              onTap:
                                  () => FeedBackHelper().showContactUsDialog(
                                    context,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.feedback_outlined,
                              label: SettingsStrings.feedback,
                              onTap:
                                  () => FeedBackHelper().showContactUsDialog(
                                    context,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.privacy_tip_outlined,
                              label: SettingsStrings.privacyPolicy,
                              onTap:
                                  () => debugPrint(
                                    SettingsStrings.privacyPolicyTapped,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.subscriptions_outlined,
                              label: SettingsStrings.subscriptionManagement,
                              onTap:
                                  () => context.read<IapBloc>().add(
                                    const IapCustomerCenterRequested(),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text(
                                SettingsStrings.autoSave,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text(
                                SettingsStrings.autoSaveDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              value: settingsState.settings.autoSaveEnabled,
                              onChanged:
                                  (enabled) => _setAutoSave(
                                    enabled,
                                    isPremium: iapState.isPremium,
                                  ),
                              activeColor: Colors.green,
                              secondary: const Icon(
                                Icons.download_for_offline,
                                color: Colors.grey,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 24),
                            _settingsItem(
                              icon: Icons.help_outline,
                              label: SettingsStrings.help,
                              onTap: () => HelpModal().showHelpDialog(context),
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.star_border_outlined,
                              label: SettingsStrings.rateUs,
                              onTap:
                                  () => FeedBackHelper().showFancyRatings(
                                    context,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _settingsItem(
                              icon: Icons.share,
                              label: SettingsStrings.share,
                              onTap: () => shareAppLink(context),
                            ),
                            const SizedBox(height: 24),
                            if (DevelopmentModeUtils.checkDevelopmentMode())
                              ..._developerOptions(iapState),
                          ],
                        ),
                  ),
            ),
      ),
    ),
  );

  List<Widget> _developerOptions(IapState iapState) => <Widget>[
    const Divider(),
    const SizedBox(height: 24),
    const Padding(
      padding: EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        SettingsStrings.developerOptions,
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    ),
    // The only way to see on device that every starter-kit module started. A
    // degraded module is designed not to crash the application, so without
    // this a capability can be silently dead and nothing says so.
    _settingsItem(
      icon: Icons.monitor_heart_outlined,
      label: SettingsStrings.moduleHealth,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ModuleHealthScreen(runtime: sl<AppRuntime>()),
        ),
      ),
    ),
    const SizedBox(height: 12),
    // Exercises every kit capability against live services, which is the only
    // way to find the failures a test cannot reach.
    _settingsItem(
      icon: Icons.science_outlined,
      label: SettingsStrings.starterKitLab,
      onTap: () => openStarterKitLab(context),
    ),
    const SizedBox(height: 12),
    _settingsItem(
      icon: Icons.restart_alt,
      label: SettingsStrings.resetOnboarding,
      onTap: _resetOnboarding,
    ),
    const SizedBox(height: 12),
    _settingsItem(
      icon: Icons.restore,
      label: SettingsStrings.resetRatingCount,
      onTap: () async {
        await AdvancedAppRatingService.resetDownloadCount();
        _showMessage(SettingsStrings.ratingCountReset);
      },
    ),
    const SizedBox(height: 12),
    StatefulBuilder(
      builder:
          (context, setLocalState) => SwitchListTile(
            title: const Text(
              SettingsStrings.devPremiumAccess,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              SettingsStrings.devPremiumDescription,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: DeveloperOptionsService.debugPremiumEnabled,
            onChanged: (enabled) async {
              await DeveloperOptionsService.setDebugPremium(enabled);
              if (!mounted) return;
              setLocalState(() {});
              context.read<IapBloc>().add(const IapRefreshRequested());
            },
            activeColor: Colors.green,
            secondary: const Icon(
              Icons.admin_panel_settings,
              color: Colors.grey,
            ),
          ),
    ),
    const SizedBox(height: 12),
    _DevAutoSaveSwitch(preferenceKey: _devAutoSaveKey, onMessage: _showMessage),
    const SizedBox(height: 12),
    _settingsItem(
      icon: Icons.notifications_active,
      label: SettingsStrings.testNotification,
      onTap: () async {
        await DeveloperOptionsService.showTestNotification();
        _showMessage(SettingsStrings.notificationSent);
      },
    ),
    const SizedBox(height: 12),
    _settingsItem(
      icon: Icons.notifications_active,
      label: SettingsStrings.testOneSignalNotification,
      onTap: _showOneSignalUser,
    ),
    const SizedBox(height: 12),
    _settingsItem(
      icon: Icons.delete_forever,
      label: SettingsStrings.deleteAllSavedAndCache,
      onTap: _deleteAllAndRestart,
    ),
    const SizedBox(height: 12),
    _settingsItem(
      icon: Icons.cleaning_services,
      label: SettingsStrings.clearCacheFreshStart,
      onTap: () {
        context.read<StatusBloc>().add(const StatusCacheClearRequested());
        _showMessage(SettingsStrings.cacheCleared);
      },
    ),
    const SizedBox(height: 20),
  ];

  Future<void> _switchBusinessMode(bool isBusinessMode, bool isPremium) async {
    if (!isBusinessMode && !isPremium) {
      final shouldUpgrade = await showPremiumUpgradeModal(
        context,
        title: SettingsStrings.unlockBusinessMode,
        message: SettingsStrings.unlockBusinessModeDescription,
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

  Future<void> _setAutoSave(bool enabled, {required bool isPremium}) async {
    if (!isPremium) {
      final shouldUpgrade = await showPremiumUpgradeModal(
        context,
        title: SettingsStrings.unlockAutoSave,
        message: SettingsStrings.unlockAutoSaveDescription,
      );
      if (shouldUpgrade == true && mounted) {
        context.read<IapBloc>().add(const IapPaywallRequested());
      }
      return;
    }
    if (!mounted) return;
    _log(enabled ? 'auto_save_enabled' : 'auto_save_disabled');
    context.read<SettingsBloc>().add(AutoSaveChanged(enabled));
    _showMessage(
      enabled
          ? SettingsStrings.autoSaveEnabledMessage
          : SettingsStrings.autoSaveDisabledMessage,
    );
  }

  Future<void> _resetOnboarding() async {
    final bloc = context.read<OnboardingBloc>();
    final reset = bloc.stream.firstWhere(
      (state) => state.status == OnboardingViewStatus.idle,
    );
    bloc.add(const OnboardingResetRequested());
    await reset;
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.onboarding,
        (_) => false,
      );
    }
  }

  Future<void> _showOneSignalUser() async {
    try {
      final userId = await DeveloperOptionsService.getPushUserId();
      if (!mounted) return;
      if (userId == null || userId.isEmpty) {
        _showMessage(SettingsStrings.pushNotSubscribed);
        return;
      }
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text(SettingsStrings.oneSignalUserId),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(SettingsStrings.yourOneSignalUserId),
                  const SizedBox(height: 8),
                  SelectableText(
                    userId,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    SettingsStrings.oneSignalInstructions,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(SettingsStrings.close),
                ),
              ],
            ),
      );
    } catch (error) {
      if (mounted) _showMessage('${SettingsStrings.errorPrefix}$error');
    }
  }

  Future<void> _deleteAllAndRestart() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text(SettingsStrings.deleting),
              ],
            ),
          ),
    );
    try {
      final savedBloc = context.read<SavedMediaBloc>();
      final statusBloc = context.read<StatusBloc>();
      final savedDone = savedBloc.stream.firstWhere(
        (state) => state.items.isEmpty,
      );
      final cacheDone = statusBloc.stream.firstWhere(
        (state) => state.images.isEmpty && state.videos.isEmpty,
      );
      savedBloc.add(const SavedMediaDeleteAllRequested());
      statusBloc.add(const StatusCacheClearRequested());
      await Future.wait(<Future<Object?>>[savedDone, cacheDone]);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMessage(SettingsStrings.allDeleted);
      Navigator.pushNamedAndRemoveUntil(context, Routes.splash, (_) => false);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showMessage('${SettingsStrings.deleteErrorPrefix}$error');
    }
  }

  void _log(String name) {
    context.read<AnalyticsBloc>().add(
      AnalyticsEventLogged(AnalyticsEventEntity(name: name)),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _settingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Material(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: _canvasColor.withOpacity(0.2),
      highlightColor: _canvasColor.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.grey[800], size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DevAutoSaveSwitch extends StatefulWidget {
  const _DevAutoSaveSwitch({
    required this.preferenceKey,
    required this.onMessage,
  });

  final String preferenceKey;
  final ValueChanged<String> onMessage;

  @override
  State<_DevAutoSaveSwitch> createState() => _DevAutoSaveSwitchState();
}

class _DevAutoSaveSwitchState extends State<_DevAutoSaveSwitch> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      if (mounted) {
        setState(
          () => _enabled = preferences.getBool(widget.preferenceKey) ?? false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: const Text(
      SettingsStrings.testAutoSave,
      style: TextStyle(fontWeight: FontWeight.w500),
    ),
    subtitle: const Text(
      SettingsStrings.testAutoSaveDescription,
      style: TextStyle(fontSize: 12, color: Colors.grey),
    ),
    value: _enabled,
    onChanged: (enabled) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(widget.preferenceKey, enabled);
      if (!mounted) return;
      setState(() => _enabled = enabled);
      if (enabled) {
        DeveloperOptionsService.startAutoSaveTestMode();
        widget.onMessage(SettingsStrings.devTestStarted);
      } else {
        DeveloperOptionsService.stopAutoSaveTestMode();
        widget.onMessage(SettingsStrings.devTestStopped);
      }
    },
    activeColor: Colors.orange,
    secondary: const Icon(Icons.speed, color: Colors.grey),
  );
}
