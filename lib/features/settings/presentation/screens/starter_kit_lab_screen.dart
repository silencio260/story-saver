import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genrevibes_ads/genrevibes_ads.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:genrevibes_consent/genrevibes_consent.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:genrevibes_device_identity/genrevibes_device_identity.dart';
import 'package:genrevibes_engagement/genrevibes_engagement.dart';
import 'package:genrevibes_feedback/genrevibes_feedback.dart';
import 'package:genrevibes_iap/genrevibes_iap.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_permissions/genrevibes_permissions.dart' as kit;
import 'package:genrevibes_remote_config/genrevibes_remote_config.dart';
import 'package:genrevibes_remote_policy/genrevibes_remote_policy.dart';
import 'package:genrevibes_starter_kit/genrevibes_starter_kit.dart';

import '../../../../bootstrap/app_env.dart';
import '../../../../bootstrap/app_runtime.dart';
import '../../../../container_injector.dart';

/// A bench for exercising every starter-kit capability on a real device.
///
/// Module health answers "did it start". This answers the harder question:
/// does it actually *work* — does an event reach the dashboard, does an
/// interstitial fill, is session replay recording, does the paywall open.
/// Those only fail against live services, which no test can stand in for.
///
/// Every action reports the real [KitResult], including the provider's own
/// error text, so a failure names its own cause instead of leaving a blank
/// screen. Nothing here is reachable outside development builds.
class StarterKitLabScreen extends StatefulWidget {
  /// Creates the bench.
  const StarterKitLabScreen({super.key});

  @override
  State<StarterKitLabScreen> createState() => _StarterKitLabScreenState();
}

class _StarterKitLabScreenState extends State<StarterKitLabScreen> {
  final List<_LogLine> _log = <_LogLine>[];
  bool _busy = false;

  void _say(String message, {bool ok = true}) {
    if (!mounted) return;
    setState(() => _log.insert(0, _LogLine(message: message, ok: ok)));
  }

  /// Runs [body] and reports whatever the kit returns, including failures.
  Future<void> _run(String label, Future<Object?> Function() body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final outcome = await body();
      if (outcome is KitResult) {
        outcome.fold(
          onSuccess: (value) => _say('$label → ${value ?? 'ok'}'),
          onFailure: (error) =>
              _say('$label → ${error.code.name}: ${error.message}', ok: false),
        );
      } else {
        _say('$label → ${outcome ?? 'ok'}');
      }
    } on Object catch (error) {
      _say('$label threw → $error', ok: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  AppRuntime get _runtime => sl<AppRuntime>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Starter Kit Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          _modules(),
          _analytics(),
          _ads(),
          _consent(),
          _purchases(),
          _push(),
          _permissions(),
          _remoteConfig(),
          _identityAndEngagement(),
          _feedbackAndCrash(),
          const SizedBox(height: 24),
          _logView(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- modules

  Widget _modules() {
    final modules = _runtime.kit.modules.values.toList()
      ..sort((a, b) => a.moduleId.compareTo(b.moduleId));
    return _Section(
      title: 'Modules',
      subtitle: '${modules.length} started',
      children: <Widget>[
        for (final module in modules)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: <Widget>[
                _StateDot(module.health.state),
                const SizedBox(width: 8),
                Expanded(child: Text(module.moduleId)),
                Text(
                  module.health.state.name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        for (final module in modules)
          if (module.health.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${module.moduleId}: ${module.health.error!.message}',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ),
      ],
    );
  }

  // -------------------------------------------------------------- analytics

  /// Every event this application can emit, fired from one place.
  ///
  /// Names are the literals the reports are built on, so what lands in
  /// Firebase and PostHog here is exactly what production sends.
  static const _events = <String>[
    'app_open',
    'splash_viewed',
    'home_viewed',
    'save_status',
    'share_app',
    'goto_app_store_page',
    'goto_splash_screen',
    'goto_home_page',
    'show_gdpr_consent_request',
    'grant_gdpr_consent',
    'grant_notification_request',
    'app_error_operation_failed',
    'switch_to_business_mode',
    'switch_to_normal_mode',
    'show_help',
    'request_whatsapp_folder_permission',
    'grant_whatsapp_folder_permission',
    'denied_whatsapp_folder_permission',
    'request_business_folder_permission',
    'grant_business_folder_permission',
    'denied_business_folder_permission',
    'grant_Android/Media_folder_permission',
    'navigate_to_folder_permission_page',
    'rating_maybe_later',
    'rating_never',
    'rating_submitted',
    'rating_4_stars',
    'rating_5_stars',
    'onboarding_complete',
    'view_paywall_modal',
    'view_paywall',
    'auto_save_enabled',
    'auto_save_disabled',
    'download_all',
    'remove_ads_clicked',
    'custom_purchase',
    'custom_paywall_cancelled',
    'custom_purchases_restored',
    'custom_customer_center_viewed',
    'ad_impression',
  ];

  Widget _analytics() {
    final pipeline = sl<AnalyticsPipeline>();
    final env = AppEnv.fromDefines();
    return _Section(
      title: 'Analytics',
      subtitle: '${_events.length} events · '
          'sinks: ${pipeline.health.details?['sinks'] ?? 'n/a'}',
      children: <Widget>[
        _Info('Consent', pipeline.health.details?['consent']?.toString() ?? '—'),
        _Info('Session replay', env.postHog.sessionReplayEnabled
            ? 'enabled (release builds only)'
            : 'off — this is a development build'),
        _Info('Replay masking',
            'text ${env.postHog.maskAllTexts ? 'masked' : 'VISIBLE'} · '
            'images ${env.postHog.maskAllImages ? 'masked' : 'VISIBLE'}'),
        _Actions(<_Action>[
          _Action('Fire all ${_events.length} events', () async {
            var failures = 0;
            for (final name in _events) {
              final result = await pipeline.track(
                AnalyticsEvent(
                  name: name,
                  properties: const <String, Object?>{'source': 'kit_lab'},
                ),
              );
              if (result.isFailure) failures++;
            }
            return failures == 0
                ? 'all ${_events.length} delivered'
                : '$failures of ${_events.length} failed';
          }),
          _Action('Fire one (kit_lab_ping)', () => pipeline.track(
                const AnalyticsEvent(name: 'kit_lab_ping'),
              )),
          _Action('Flush now', pipeline.flush),
          _Action('Identify as kit-lab-user', () => pipeline.identify(
                const AnalyticsUser(id: 'kit-lab-user'),
              )),
        ]),
      ],
    );
  }

  // -------------------------------------------------------------------- ads

  Widget _ads() {
    final ads = sl<AdProvider>();
    final policy = sl<AdPolicyController>();
    const interstitial = AppPlacements.interstitial;
    return _Section(
      title: 'Ads',
      subtitle: ads.providerId,
      children: <Widget>[
        _Info('Interstitial ready', ads.isReady(interstitial).toString()),
        _Info('Premium (suppresses ads)', policy.isPremium.toString()),
        _Actions(<_Action>[
          _Action('Load interstitial', () => ads.load(interstitial)),
          _Action('Show interstitial', () => ads.show(interstitial)),
          _Action('Discard interstitial', () => ads.discard(interstitial)),
          _Action('Toggle premium', () async {
            policy.setPremium(!policy.isPremium);
            return 'premium = ${policy.isPremium}';
          }),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Banners render through AdMobBannerView, which holds its own unit '
          'and is not served by this provider.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- consent

  Widget _consent() {
    final consent = sl<ConsentGate>();
    final snapshot = consent.snapshot;
    return _Section(
      title: 'Consent (UMP)',
      subtitle: snapshot.state.name,
      children: <Widget>[
        _Info('Personalized work allowed',
            snapshot.allowsPersonalizedWork.toString()),
        _Info('Form available', snapshot.formAvailable.toString()),
        _Info('Privacy options required',
            snapshot.privacyOptionsRequired.toString()),
        _Actions(<_Action>[
          _Action('Show privacy options form', consent.showPrivacyOptions),
          _Action('Reset consent (QA only)', consent.reset),
        ]),
      ],
    );
  }

  // -------------------------------------------------------------- purchases

  Widget _purchases() {
    final iap = sl<IapProvider>();
    return _Section(
      title: 'Purchases',
      subtitle: iap.providerId,
      children: <Widget>[
        _Actions(<_Action>[
          _Action('Read entitlements', () async {
            final result = await iap.getEntitlements();
            return result.fold(
              onSuccess: (s) => s.activeEntitlementIds.isEmpty
                  ? 'no active entitlements'
                  : s.activeEntitlementIds.join(', '),
              onFailure: (e) => throw StateError(e.message),
            );
          }),
          _Action('Fetch products', () async {
            final result = await iap.getProducts();
            return result.fold(
              onSuccess: (products) => '${products.length} products',
              onFailure: (e) => throw StateError(e.message),
            );
          }),
          _Action('Present paywall', () => iap.presentPaywall()),
          _Action('Present customer centre', iap.presentCustomerCenter),
          _Action('Restore purchases', iap.restorePurchases),
        ]),
      ],
    );
  }

  // ------------------------------------------------------------------- push

  Widget _push() {
    final push = sl<PushNotificationProvider>();
    return _Section(
      title: 'Push',
      subtitle: push.providerId,
      children: <Widget>[
        _Actions(<_Action>[
          _Action('Read subscription state', () async {
            final result = await push.getSubscriptionState();
            return result.fold(
              onSuccess: (s) => 'permission ${s.permission.name} · '
                  'optedIn ${s.optedIn} · id ${s.subscriptionId ?? '—'}',
              onFailure: (e) => throw StateError(e.message),
            );
          }),
          _Action('Request permission', () => push.requestPermission()),
          _Action('Opt in', push.optIn),
          _Action('Opt out', push.optOut),
          _Action('Tag kit_lab=true',
              () => push.setTags(const <String, String>{'kit_lab': 'true'})),
        ]),
      ],
    );
  }

  // ------------------------------------------------------------ permissions

  Widget _permissions() {
    final permissions = sl<kit.PermissionProvider>();
    const kinds = <kit.PermissionKind>[
      kit.PermissionKind.photos,
      kit.PermissionKind.videos,
      kit.PermissionKind.audio,
      kit.PermissionKind.storage,
      kit.PermissionKind.manageExternalStorage,
      kit.PermissionKind.notifications,
    ];
    return _Section(
      title: 'Permissions',
      subtitle: permissions.providerId,
      children: <Widget>[
        _Actions(<_Action>[
          _Action('Check all', () async {
            final parts = <String>[];
            for (final kind in kinds) {
              final result = await permissions.check(kind);
              parts.add(
                '${kind.name}=${result.fold(
                  onSuccess: (state) => state.name,
                  onFailure: (_) => 'error',
                )}',
              );
            }
            return parts.join(' · ');
          }),
          for (final kind in kinds)
            _Action('Request ${kind.name}', () => permissions.request(kind)),
          _Action('Open app settings', permissions.openSettings),
        ]),
      ],
    );
  }

  // ---------------------------------------------------------- remote config

  Widget _remoteConfig() {
    final config = sl<RemoteConfigCoordinator>();
    final snapshot = config.current;
    return _Section(
      title: 'Remote config',
      subtitle: 'read ${snapshot.observedAt.toIso8601String()}',
      children: <Widget>[
        _Info('Ads enabled', snapshot.read(AdsPolicyKeys.adsEnabled).toString()),
        _Info('First interstitial after',
            '${snapshot.read(AdsPolicyKeys.timeBeforeFirstInterstitial)}s'),
        _Info('Min interstitial gap',
            '${snapshot.read(AdsPolicyKeys.minInterstitialInterval)}s'),
        _Info('Min banner gap',
            '${snapshot.read(AdsPolicyKeys.minBannerInterval)}s'),
        _Actions(<_Action>[
          _Action('Refresh from server', config.refresh),
        ]),
      ],
    );
  }

  // ------------------------------------------------- identity & engagement

  Widget _identityAndEngagement() {
    final identity = sl<DeviceIdentityResolver>();
    final retention = sl<RetentionTracker>();
    return _Section(
      title: 'Identity & engagement',
      subtitle: identity.current?.installId ?? 'unresolved',
      children: <Widget>[
        _Info('Tracking', identity.current?.tracking.name ?? '—'),
        _Info('Advertising id', identity.current?.advertisingId ?? 'none'),
        _Actions(<_Action>[
          _Action('Resolve identity', () => identity.resolve()),
          _Action('Prompt tracking (ATT)',
              () => identity.resolve(promptTracking: true)),
          _Action('Read engagement', () async {
            final s = retention.snapshot;
            return 'day ${s.daysSinceInstall} · opens ${s.totalOpens} · '
                'active ${s.activeDays}d · last seen ${s.daysSinceLastOpen}d ago';
          }),
          _Action('Record app open', retention.recordAppOpen),
          _Action('Record session', retention.recordSession),
        ]),
      ],
    );
  }

  // ------------------------------------------------------- feedback & crash

  Widget _feedbackAndCrash() {
    final feedback = sl<FeedbackProvider>();
    final crash = sl<CrashCoordinator>();
    return _Section(
      title: 'Feedback & crash',
      subtitle: feedback.providerId,
      children: <Widget>[
        _Actions(<_Action>[
          _Action('Submit test feedback', () => feedback.submit(
                FeedbackSubmission(
                  message: 'Starter Kit Lab test submission',
                  kind: FeedbackKind.feedback,
                ),
              )),
          _Action('Submit 5-star rating',
              () => feedback.submitRatingAndReview(rating: 5, review: 'lab')),
          _Action('Record non-fatal', () => crash.report(
                CrashReport(
                  error: StateError('Starter Kit Lab non-fatal'),
                  stackTrace: StackTrace.current,
                  fatal: false,
                  source: CrashSource.manual,
                ),
              )),
          _Action('Log breadcrumb', () => crash.log('kit lab breadcrumb')),
          _Action('Throw uncaught async', () async {
            unawaited(Future<void>.error(StateError('Kit Lab uncaught')));
            return 'thrown — expect it in the zone handler';
          }),
        ]),
      ],
    );
  }

  // -------------------------------------------------------------------- log

  Widget _logView() {
    if (_log.isEmpty) {
      return const Text(
        'Results appear here.',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Results',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(_log.clear),
              child: const Text('Clear'),
            ),
          ],
        ),
        for (final line in _log)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              line.message,
              style: TextStyle(
                fontSize: 12,
                color: line.ok ? Colors.green.shade800 : Colors.red.shade700,
              ),
            ),
          ),
      ],
    );
  }
}

class _LogLine {
  const _LogLine({required this.message, required this.ok});
  final String message;
  final bool ok;
}

class _Action {
  const _Action(this.label, this.run);
  final String label;
  final Future<Object?> Function() run;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ...children,
          const Divider(height: 28),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.actions);
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_StarterKitLabScreenState>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: <Widget>[
          for (final action in actions)
            OutlinedButton(
              onPressed: state._busy
                  ? null
                  : () => state._run(action.label, action.run),
              child: Text(action.label, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _StateDot extends StatelessWidget {
  const _StateDot(this.state);
  final ModuleState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      ModuleState.ready => Colors.green,
      ModuleState.degraded => Colors.orange,
      ModuleState.failed => Colors.red,
      ModuleState.disabled => Colors.grey,
      _ => Colors.blueGrey,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
