import 'package:flutter/material.dart';
import 'package:genrevibes_starter_kit/starter_kit.dart';

class PostHogWrapper extends StatefulWidget {
  final Widget child;
  final String apiKey;
  final String host;
  final bool captureLocalStorage;
  final bool captureApplicationLifecycleEvents;

  const PostHogWrapper({
    super.key,
    required this.child,
    required this.apiKey,
    this.host = 'https://app.posthog.com',
    this.captureLocalStorage = false,
    this.captureApplicationLifecycleEvents = true,
  });

  @override
  State<PostHogWrapper> createState() => _PostHogWrapperState();
}

class _PostHogWrapperState extends State<PostHogWrapper> {
  @override
  void initState() {
    super.initState();
    _initPostHog();
  }

  Future<void> _initPostHog() async {
    final postHog = StarterKit.postHog;
    if (postHog != null && widget.apiKey.isNotEmpty) {
      await postHog.initialize(apiKey: widget.apiKey, host: widget.host);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
