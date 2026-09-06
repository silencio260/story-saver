import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:storysaver/core/utils/development_mode_utils.dart';

class PostHogWrapper {
  /// PostHog is configured by the kit's analytics sink, from the bootstrap.
  ///
  /// This was fire-and-forget, so it raced `runApp`.
  static init() async {}

  // static startSessionReplay({bool record = false}) async {
  //   // Reset the current instance
  //   await Posthog().reset();
  //
  //   // Create new config with session replay enabled/disabled
  //   final api_key = const String.fromEnvironment("posthog_api_key");
  //   final config = PostHogConfig(api_key);
  //   config.host = 'https://us.i.posthog.com';
  //   config.debug = true;
  //   config.captureApplicationLifecycleEvents = true;
  //   config.sessionReplay = record; // Use the parameter
  //   config.sessionReplayConfig.maskAllTexts = false;
  //   config.sessionReplayConfig.maskAllImages = false;
  //
  //   // Re-setup PostHog with new config
  //   await Posthog().setup(config);
  // }
}
