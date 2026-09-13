import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../analytics/data/services/analytics_service.dart';
import '../../../monetization/data/services/subscription_service.dart';

/// Milestones contain timings and mode only, never file names or status content.
class StatusConnectionJourney {
  StatusConnectionJourney._();
  static final instance = StatusConnectionJourney._();
  Stopwatch? _elapsed;
  bool _business = false;
  bool _displayRecorded = false;
  bool _saveRecorded = false;

  void begin({required bool business}) {
    _elapsed ??= Stopwatch()..start();
    _business = business;
    record('status_connection_viewed');
  }

  void record(String name) => unawaited(
    AnalyticsService.track(name, {
      'business_mode': _business,
      if (_elapsed != null) 'elapsed_ms': _elapsed!.elapsedMilliseconds,
    }),
  );

  Future<void> displayed({required bool business}) async {
    if (_displayRecorded) return;
    _displayRecorded = true;
    _business = business;
    final access = SubscriptionManager();
    final first = !access.hasReachedFirstStatus;
    await access.markFirstStatusReached();
    if (first || _elapsed != null)
      record('status_connection_first_status_displayed');
  }

  Future<void> saved() async {
    if (_saveRecorded) return;
    _saveRecorded = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('status_connection_first_save') == true) return;
    await prefs.setBool('status_connection_first_save', true);
    record('status_connection_first_save');
  }

  static Future<bool> openWhatsApp({required bool business}) async {
    instance.record('status_connection_open_whatsapp');
    try {
      return await const MethodChannel(
            'story_saver/status_directory',
          ).invokeMethod<bool>('openWhatsApp', {'business': business}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
