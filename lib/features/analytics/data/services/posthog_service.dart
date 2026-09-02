import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:storysaver/core/utils/development_mode_utils.dart';

class PostHogWrapper {
  static init() async {
    // print('PostHog wrapper init - checkDevelopmentMode - ${DevelopmentModeUtils.checkDevelopmentMode()}');

    final api_key = const String.fromEnvironment("posthog_api_key");
    final config = PostHogConfig(api_key);
    config.host = 'https://us.i.posthog.com';
    config.debug = true;
    config.captureApplicationLifecycleEvents = true;
    // check https://posthog.com/docs/session-replay/installation?tab=Flutter
    // for more config and to learn about how we capture sessions on mobile
    // and what to expect
    config.sessionReplay =
        DevelopmentModeUtils.checkDevelopmentMode() ? false : true;
    // choose whether to mask images or text
    config.sessionReplayConfig.maskAllTexts = false;
    config.sessionReplayConfig.maskAllImages = false;
    // Setup PostHog with the given Context and Config
    await Posthog().setup(config);
  }

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
