import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:genrevibes_analytics/genrevibes_analytics.dart';
import 'package:path_provider/path_provider.dart';

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
    return <String, Object?>{'platform': Platform.operatingSystem, ...extra};
  }

  static AnalyticsPipeline? _pipeline;
  static bool _draining = false;

  static void bind(AnalyticsPipeline pipeline) => _pipeline = pipeline;

  /// Never let diagnostics interrupt an operation. Background isolates persist
  /// one file per event, avoiding shared-preference read/modify/write races.
  static Future<void> track(
    String name, [
    Map<String, Object?> properties = const {},
  ]) async {
    final record = <String, Object?>{
      'name': name,
      'properties': _base(properties),
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final pipeline =
          _pipeline ??
          (sl.isRegistered<AnalyticsPipeline>()
              ? sl<AnalyticsPipeline>()
              : null);
      if (pipeline != null && pipeline.consent != AnalyticsConsent.granted)
        return;
      if (pipeline != null && pipeline.health.isOperational) {
        if (await _deliver(pipeline, record)) return;
        // Consent suppression is intentional, never queue it for later replay.
        if (pipeline.consent != AnalyticsConsent.granted) return;
      }
      final directory = await _queueDirectory();
      final id =
          '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final temporary = File('${directory.path}/$id.tmp');
      await temporary.writeAsString(jsonEncode(record), flush: true);
      await temporary.rename('${directory.path}/$id.json');
    } catch (error) {
      debugPrint('Analytics event $name could not be recorded: $error');
    }
  }

  static Future<Directory> _queueDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/analytics_pending').create(recursive: true);
  }

  static Future<bool> _deliver(
    AnalyticsPipeline pipeline,
    Map<String, dynamic> record,
  ) async {
    final result = await pipeline.track(
      AnalyticsEvent(
        name: record['name'] as String,
        properties: {
          ...Map<String, Object?>.from(record['properties'] as Map),
          'event_occurred_at': record['occurred_at'] as String,
        },
        occurredAt: DateTime.parse(record['occurred_at'] as String),
      ),
    );
    return result.fold(
      onSuccess: (report) {
        if (!report.isCompleteSuccess) {
          debugPrint(
            'Analytics ${record['name']}: delivered=${report.successfulSinks}, '
            'failed=${report.failures.keys}, suppressed=${report.suppressedByConsent}',
          );
        }
        // Do not replay to successful providers after a partial failure.
        return report.wasDelivered || report.suppressedByConsent;
      },
      onFailure: (error) {
        debugPrint('Analytics ${record['name']} failed: ${error.message}');
        return false;
      },
    );
  }

  /// Called at launch and resume. Records retain their original occurrence time.
  static Future<void> drainPending() async {
    final pipeline = _pipeline;
    if (_draining || pipeline == null || !pipeline.health.isOperational) return;
    _draining = true;
    try {
      final directory = await _queueDirectory();
      await for (final entry in directory.list()) {
        if (entry is! File || !entry.path.endsWith('.json')) continue;
        if (DateTime.now().difference((await entry.stat()).modified).inDays >=
            7) {
          await entry.delete();
          continue;
        }
        try {
          final record =
              jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
          if (await _deliver(pipeline, record)) await entry.delete();
        } on FormatException {
          await entry.delete();
        }
      }
    } catch (error) {
      debugPrint('Analytics queue drain failed: $error');
    } finally {
      _draining = false;
    }
  }

  static Future<void> _track(
    String name, [
    Map<String, Object?> extra = const {},
  ]) => track(name, extra);

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
  static Future<void> logRatingMaybeLater() async =>
      _track('rating_maybe_later');

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
  static Future<void> logViewPaywallModal() async =>
      _track('view_paywall_modal');

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
    await _track('custom_purchase', <String, Object?>{
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
    await _track('custom_paywall_cancelled', <String, Object?>{
      'entitlement_id': entitlementId,
    });
  }

  /// Purchases were restored.
  static Future<void> logCustomPurchasesRestored({
    required String entitlementId,
  }) async {
    await _track('custom_purchases_restored', <String, Object?>{
      'entitlement_id': entitlementId,
    });
  }

  /// The customer centre was opened.
  static Future<void> logCustomCustomerCenterViewed() async =>
      await _track('custom_customer_center_viewed');
}
