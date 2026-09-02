import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/legacy_app_constants.dart';
import '../../../saved_media/data/services/auto_save_service.dart';
import 'settings_base_local_data_source.dart';

export 'settings_base_local_data_source.dart';

class SettingsLocalDataSource implements SettingsBaseLocalDataSource {
  const SettingsLocalDataSource();

  @override
  Future<bool> loadAutoSave() async =>
      (await SharedPreferences.getInstance()).getBool(
        AppConstants().IS_AUTO_SAVE_ENABLED,
      ) ??
      false;

  @override
  Future<bool> setAutoSave(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(AppConstants().IS_AUTO_SAVE_ENABLED, enabled);
    if (enabled) {
      await AutoSaveService.registerPeriodicTask();
    } else {
      await AutoSaveService.cancelAllTasks();
    }
    return enabled;
  }

  @override
  Future<void> shareApp() async {
    await Share.share(
      'Shared from Story Saver: ${AppConstants().GOOGLE_PLAY_STORE_LINK}',
    );
  }

  @override
  Future<void> rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  }

  @override
  Future<void> contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@genrevibes.com',
      queryParameters: <String, String>{'subject': 'Story Saver support'},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Unable to open the support email app.');
    }
  }
}
