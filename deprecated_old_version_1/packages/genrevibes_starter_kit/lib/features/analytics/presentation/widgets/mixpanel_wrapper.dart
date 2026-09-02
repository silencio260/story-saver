import 'package:flutter/material.dart';
import 'package:genrevibes_starter_kit/starter_kit.dart';
import 'package:mixpanel_flutter_session_replay/mixpanel_flutter_session_replay.dart';

/// Initializes Mixpanel (events + session replay) and mounts the session-replay
/// recorder at the root of the widget tree.
///
/// Mirrors [PostHogWrapper]: initialization runs in [initState] so the app boots
/// immediately; the session-replay instance is plugged into
/// [MixpanelSessionReplayWidget] once init completes (it tolerates a null
/// instance until then).
class MixpanelWrapper extends StatefulWidget {
  final Widget child;
  final String token;

  /// Anonymous, stable id (the app's install UUID). Seeds session replay and
  /// Mixpanel's distinct id. Never PII.
  final String distinctId;
  final bool maskAllText;
  final bool maskAllImages;
  final double sessionsPercent;
  final bool wifiOnly;

  /// When false, session replay is not initialized (events still are). Used to
  /// keep replay off in dev/debug builds.
  final bool enableSessionReplay;

  const MixpanelWrapper({
    super.key,
    required this.child,
    required this.token,
    required this.distinctId,
    this.maskAllText = true,
    this.maskAllImages = true,
    this.sessionsPercent = 100.0,
    this.wifiOnly = false,
    this.enableSessionReplay = true,
  });

  @override
  State<MixpanelWrapper> createState() => _MixpanelWrapperState();
}

class _MixpanelWrapperState extends State<MixpanelWrapper> {
  @override
  void initState() {
    super.initState();
    _initMixpanel();
  }

  Future<void> _initMixpanel() async {
    final mixpanel = StarterKit.mixpanel;
    if (mixpanel != null && widget.token.isNotEmpty) {
      await mixpanel.initialize(
        token: widget.token,
        distinctId: widget.distinctId,
        maskAllText: widget.maskAllText,
        maskAllImages: widget.maskAllImages,
        sessionsPercent: widget.sessionsPercent,
        wifiOnly: widget.wifiOnly,
        enableSessionReplay: widget.enableSessionReplay,
      );
      // Rebuild so MixpanelSessionReplayWidget picks up the live instance.
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final MixpanelSessionReplay? replay = StarterKit.mixpanel?.sessionReplay;
    return MixpanelSessionReplayWidget(
      instance: replay,
      child: widget.child,
    );
  }
}
