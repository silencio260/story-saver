import 'package:flutter/widgets.dart';
import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';

/// Screen tracking and session replay, sourced from the analytics adapter.
///
/// This used to import `posthog_flutter` directly, which kept a vendor SDK in
/// the application's dependency list purely for two widgets. The adapter owns
/// that surface now, so swapping analytics providers is a change to the
/// composition root rather than to the widget tree.
class AnalyticsScope extends StatelessWidget {
  const AnalyticsScope({required this.child, super.key});

  final Widget child;

  static NavigatorObserver get navigatorObserver => PostHogScope.navigatorObserver;

  @override
  Widget build(BuildContext context) => PostHogScope(child: child);
}
