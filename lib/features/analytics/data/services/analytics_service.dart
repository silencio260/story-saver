import 'dart:async';
import 'dart:io' show Platform;

import 'package:genrevibes_analytics/genrevibes_analytics.dart';

import '../../../../container_injector.dart';

/// The application's named analytics events, delivered through the starter kit.
///
/// This replaces the Firebase-specific service of the same name. Every event
/// name and every parameter is carried over unchanged, so the reports built on
/// them keep working: this migration moves delivery, not meaning.
///
/// The methods stay static and keep their signatures because roughly twenty
/// call sites across rating, purchases, permissions and sharing use them, and
/// those features migrate in their own steps. When a feature moves, its call
/// sites move to the pipeline directly and the method here goes with them.
///
/// Delivery now fans out to every configured sink rather than Firebase alone,
/// passes the consent gate, and resolves names through remote configuration.
abstract final class AnalyticsService {
  const AnalyticsService._();

  /// Carried over verbatim: every event in this app reported the platform.
  static Map<String, Object?> _base([Map<String, Object?> extra = const {}]) {
    return <String, Object?>{
      'platform': Platform.operatingSystem,
      ...extra,
    };
  }

  static void _track(String name, [Map<String, Object?> extra = const {}]) {
    // Fire and forget, as the previous implementation did. A failed delivery
    // is recorded on the pipeline's own health; it must never interrupt the
    // user action that triggered it.
    unawaited(
      sl<AnalyticsPipeline>().track(
        AnalyticsEvent(name: name, properties: _base(extra)),
      ),
    );
  }

  /// A status was saved.
  ///
  /// Was an instance method on the old service, for no reason the call sites
  /// depended on; it is static here like the rest.
  static Future<void> logSaveStatus() async => _track('save_status');

  /// The user shared the application.
  static Future<void> logShareApp() async => _track('share_app');

  /// The user opened the store listing.
  static Future<void> logGoToAppStorePage() async =>
      _track('goto_app_store_page');

  /// The help modal was shown.
  static Future<void> logShowHelpModal() async => _track('show_help');

  /// Android media-folder permission was granted.
  static Future<void> logGrantAndroidMediaFolderPermission() async =>
      _track('grant_android_media_folder_permission');

  /// The rating prompt was postponed.
  static Future<void> logRatingMaybeLater() async => _track('rating_maybe_later');

  /// The rating prompt was declined permanently.
  static Future<void> logRatingNever() async => _track('rating_never');

  /// A rating was submitted.
  static Future<void> logRatingSubmitted(int stars) async =>
      _track('rating_submitted', <String, Object?>{'star_count': stars});

  /// A four-star rating was given.
  static Future<void> logRating4Stars() async => _track('rating_4_stars');

  /// A five-star rating was given.
  static Future<void> logRating5Stars() async => _track('rating_5_stars');

  /// The in-app paywall modal was shown.
  static Future<void> logViewPaywallModal() async => _track('view_paywall_modal');

  /// The paywall was shown.
  static Future<void> logViewPaywall() async => _track('view_paywall');

  /// A bulk download was started.
  static Future<void> logDownloadAll() async => _track('download_all');

  /// A purchase completed.
  static Future<void> logCustomPurchase({
    required String currency,
    required double price,
    required String productId,
    required String entitlementId,
  }) async {
    _track('custom_purchase', <String, Object?>{
      'currency': currency,
      'value': price,
      'item_id': productId,
      'item_name': entitlementId,
      'quantity': 1,
    });
  }

  /// The paywall was dismissed without purchasing.
  static Future<void> logCustomPaywallCancelled({
    required String entitlementId,
  }) async {
    _track('custom_paywall_cancelled', <String, Object?>{
      'entitlement_id': entitlementId,
    });
  }

  /// Purchases were restored.
  static Future<void> logCustomPurchasesRestored({
    required String entitlementId,
  }) async {
    _track('custom_purchases_restored', <String, Object?>{
      'entitlement_id': entitlementId,
    });
  }

  /// The customer centre was opened.
  static Future<void> logCustomCustomerCenterViewed() async =>
      _track('custom_customer_center_viewed');
}
