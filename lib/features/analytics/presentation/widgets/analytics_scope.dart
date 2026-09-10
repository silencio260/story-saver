import 'package:flutter/widgets.dart';
import 'package:genrevibes_analytics_firebase/genrevibes_analytics_firebase.dart';
import 'package:genrevibes_analytics_posthog/genrevibes_analytics_posthog.dart';

/// Screen tracking and session replay, sourced from the analytics adapters.
///
/// This used to import `posthog_flutter` directly, which kept a vendor SDK in
/// the application's dependency list purely for two widgets. The adapters own
/// that surface now, so swapping analytics providers is a change to the
/// composition root rather than to the widget tree.
class AnalyticsScope extends StatelessWidget {
  const AnalyticsScope({required this.child, super.key});

  final Widget child;

  /// Every provider's screen tracking.
  ///
  /// One observer per provider, not one shared observer feeding the pipeline:
  /// each records screens natively — PostHog as `$screen`, Firebase as
  /// `screen_view` with the screen context it attaches to later events — and a
  /// pipeline-level observer on top would count every navigation twice in
  /// PostHog.
  ///
  /// Firebase used to be missing from this list, in the pre-kit app as well,
  /// so its screen reports and DebugView had no navigation at all.
  static List<NavigatorObserver> get navigatorObservers => <NavigatorObserver>[
        PostHogScope.navigatorObserver,
        FirebaseScreenTracking.navigatorObserver,
      ];

  @override
  Widget build(BuildContext context) => PostHogScope(child: child);
}
