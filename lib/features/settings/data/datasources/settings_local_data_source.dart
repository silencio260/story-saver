import 'dart:async';

import 'package:genrevibes_app_links/genrevibes_app_links.dart';
import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_app_rating/genrevibes_app_rating.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/legacy_app_constants.dart';
import '../../../saved_media/data/services/auto_save_service.dart';
import 'settings_base_local_data_source.dart';

export 'settings_base_local_data_source.dart';

class SettingsLocalDataSource implements SettingsBaseLocalDataSource {
  /// Creates the data source over the kit's link and review capabilities.
  ///
  /// Sharing, the store listing and the support mailbox were three separate
  /// hand-built launches here — a `Share.share` with an inline string, an
  /// `InAppReview` availability dance, and a `mailto:` Uri assembled by hand.
  /// All three are policy that belongs in one place, so they now go through
  /// [AppLinkActions] and [StoreReviewProvider], which know which store this
  /// platform uses and what the share text says.
  const SettingsLocalDataSource({
    required AppLinkActions links,
    required StoreReviewProvider storeReview,
  })  : _links = links,
        _storeReview = storeReview;

  final AppLinkActions _links;
  final StoreReviewProvider _storeReview;

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
  Future<void> shareApp() => _unwrap(_links.shareApp());

  @override
  Future<void> rateApp() async {
    final available = (await _storeReview.isAvailable()).fold(
      onSuccess: (value) => value,
      onFailure: (_) => false,
    );
    // The native flow is quota-limited and declines silently once a user has
    // seen it recently, so the listing is the only reliable fallback.
    await _unwrap(
      available
          ? await _storeReview.requestReview()
          : await _storeReview.openStoreListing(),
    );
  }

  @override
  Future<void> contactSupport() => _unwrap(_links.contactSupport());

  /// Keeps the `Future<void>`-that-throws contract this layer is built on.
  ///
  /// The repository above still expects a throw, so a `KitFailure` is turned
  /// back into one here rather than leaking the result type through a layer
  /// that has no way to render it.
  Future<void> _unwrap(FutureOr<KitResult<void>> result) async {
    final resolved = await result;
    resolved.fold(
      onSuccess: (_) {},
      onFailure: (error) => throw StateError(error.message),
    );
  }
}
