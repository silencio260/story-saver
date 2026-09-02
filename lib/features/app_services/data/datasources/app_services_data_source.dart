import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/utils/development_mode_utils.dart';
import '../../../analytics/data/services/posthog_service.dart';
import '../../../analytics/data/services/user_targeting_manager.dart';
import '../../../monetization/data/services/ads/ad_config.dart';
import '../../../saved_media/data/services/auto_save_service.dart';
import '../services/gdpr_consent_service.dart';
import 'app_services_base_data_source.dart';

export 'app_services_base_data_source.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == AutoSaveService.taskName) {
      await AutoSaveService.initialize();
      await AutoSaveService.executeBackgroundTask();
    }
    return true;
  });
}

class AppServicesDataSource implements AppServicesBaseDataSource {
  const AppServicesDataSource();

  @override
  Future<void> initialize() async {
    await MediaStore.ensureInitialized();
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: DevelopmentModeUtils.checkDevelopmentMode(),
    );
    await handleGDPRConsent();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>['5e2d630f-0073-4c73-b2b8-f05738eb5b6f'],
      ),
    );
    await AdConfig.ensureInitialized();
    PostHogWrapper.init();
    await UserTargetingManager.startTracking();
    await AutoSaveService.checkAndResumeDevMode();
  }
}
