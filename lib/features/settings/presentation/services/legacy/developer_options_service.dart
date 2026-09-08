import 'package:genrevibes_notifications/genrevibes_notifications.dart';

import '../../../../../container_injector.dart';
import '../../../../monetization/data/services/subscription_service.dart';
import '../../../../saved_media/data/services/auto_save_service.dart';

/// Boundary for retained developer-only utilities that call platform services.
class DeveloperOptionsService {
  const DeveloperOptionsService._();

  static bool get debugPremiumEnabled =>
      SubscriptionManager().debugOverridePremium;

  static Future<void> setDebugPremium(bool enabled) =>
      SubscriptionManager().toggleDebugPremium(enabled);

  static void startAutoSaveTestMode() => AutoSaveService.startDevTestMode();

  static void stopAutoSaveTestMode() => AutoSaveService.stopDevTestMode();

  static Future<void> showTestNotification() =>
      AutoSaveService.showTestNotification();

  static Future<String?> getPushUserId() async {
    final result = await sl<PushNotificationProvider>().getSubscriptionState();
    return result.fold(
      onSuccess: (state) => state.subscriptionId,
      onFailure: (_) => null,
    );
  }
}
