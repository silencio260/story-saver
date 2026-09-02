import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsScope extends StatelessWidget {
  const AnalyticsScope({required this.child, super.key});

  final Widget child;

  static NavigatorObserver get navigatorObserver => PosthogObserver();

  @override
  Widget build(BuildContext context) => PostHogWidget(child: child);
}
