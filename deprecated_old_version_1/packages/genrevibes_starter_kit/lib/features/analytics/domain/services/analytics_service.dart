import '../utils/analytics_names.dart';
import '../../../../core/utils/starter_log.dart';
import '../../presentation/bloc/analytics_bloc.dart';
import '../../presentation/bloc/analytics_event.dart' as bloc_event;
import '../entities/ad_revenue_event.dart';
import '../entities/analytics_event.dart';

/// Service to simplify logging of standard and custom analytics events
///
/// Uses AnalyticsNames to resolve the actual event names, allowing for
/// dynamic renaming via Remote Config mapping.
class AnalyticsService {
  final AnalyticsBloc _bloc;
  final AnalyticsNames _names = AnalyticsNames.instance;

  AnalyticsService(this._bloc);

  /// Log a completely custom event
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    bool debugLog = false,
  }) async {
    final event = AnalyticsEvent(name: eventName, parameters: parameters ?? {});
    _bloc.add(bloc_event.AnalyticsLogEvent(event));

    if (debugLog) {
      StarterLog.logAnalyticsEvent(eventName, parameters ?? {}, debugLog: true);
    }
  }

  /// Associate all subsequent events with a stable (anonymous) user id.
  /// Fans out to Firebase Analytics + Crashlytics id + Mixpanel identify.
  Future<void> setUserId(String userId, {bool debugLog = false}) async {
    _bloc.add(bloc_event.AnalyticsSetUserId(userId: userId));
    if (debugLog) {
      StarterLog.d('Set User Id', tag: 'ANALYTICS', debugLog: true);
    }
  }

  /// Set a user/profile property (fans out to Firebase user property +
  /// Mixpanel people property). Use non-PII values only.
  Future<void> setUserProperty(
    String name,
    String value, {
    bool debugLog = false,
  }) async {
    _bloc.add(bloc_event.AnalyticsSetUserProperty(name: name, value: value));
    if (debugLog) {
      StarterLog.d(
        'Set User Property: $name',
        tag: 'ANALYTICS',
        debugLog: true,
        values: {name: value},
      );
    }
  }

  /// Log ad revenue event
  Future<void> logAdRevenue(
    AdRevenueEvent event, {
    bool debugLog = false,
  }) async {
    _bloc.add(bloc_event.AnalyticsLogAdRevenue(event));

    if (debugLog) {
      StarterLog.logAdEvent(
        'ad_impression',
        adUnitId: event.adUnitId,
        format: event.adFormat,
        value: event.value,
        currency: event.currency,
        debugLog: true,
      );
    }
  }

  /// Specialized Category Logs
  Future<void> logRetentionEvent(
    String eventName,
    Map<String, dynamic> parameters, {
    bool debugLog = false,
  }) async {
    _bloc.add(
      bloc_event.AnalyticsLogRetention(name: eventName, parameters: parameters),
    );
    if (debugLog) {
      StarterLog.d(
        'Retention Event: $eventName',
        tag: 'ANALYTICS',
        debugLog: true,
        values: parameters,
      );
    }
  }

  Future<void> logUserSegmentEvent(
    String eventName,
    Map<String, dynamic> parameters, {
    bool debugLog = false,
  }) async {
    _bloc.add(
      bloc_event.AnalyticsLogUserSegment(
        name: eventName,
        parameters: parameters,
      ),
    );
    if (debugLog) {
      StarterLog.d(
        'User Segment Event: $eventName',
        tag: 'ANALYTICS',
        debugLog: true,
        values: parameters,
      );
    }
  }

  Future<void> logTargetingEvent(
    String eventName,
    Map<String, dynamic> parameters, {
    bool debugLog = false,
  }) async {
    _bloc.add(
      bloc_event.AnalyticsLogTargeting(name: eventName, parameters: parameters),
    );
    if (debugLog) {
      StarterLog.d(
        'Targeting Event: $eventName',
        tag: 'ANALYTICS',
        debugLog: true,
        values: parameters,
      );
    }
  }

  /// Crashlytics & Error Tracking
  void recordFlutterError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
    bool debugLog = true,
  }) {
    _bloc.add(
      bloc_event.AnalyticsRecordFlutterError(
        error: error,
        stack: stack,
        fatal: fatal,
      ),
    );
    if (debugLog) {
      StarterLog.e(
        'Flutter Error Recorded',
        tag: 'CRASH',
        error: error,
        stackTrace: stack,
      );
    }
  }

  void recordError(
    dynamic error,
    dynamic stack, {
    bool fatal = false,
    bool debugLog = true,
  }) {
    _bloc.add(
      bloc_event.AnalyticsRecordError(error: error, stack: stack, fatal: fatal),
    );
    if (debugLog) {
      StarterLog.e(
        'Error Recorded',
        tag: 'CRASH',
        error: error,
        stackTrace: stack,
      );
    }
  }

  void testCrash() {
    StarterLog.w('Triggering Test Crash...', tag: 'CRASH', debugLog: true);
    throw const FormatException(
      'StarterKit: Custom format error for Crashlytics testing',
    );
  }

  // --- Standard Events ---

  void logAppOpen({bool debugLog = false}) =>
      logEvent(_names.appOpen, debugLog: debugLog);

  void logOnboardingComplete({bool debugLog = false}) =>
      logEvent(_names.onboardingComplete, debugLog: debugLog);

  void logViewPaywall({String? source, bool debugLog = false}) => logEvent(
    _names.viewPaywall,
    parameters: {if (source != null) 'source': source},
    debugLog: debugLog,
  );

  void logStartTrial({String? productId, bool debugLog = false}) => logEvent(
    _names.startTrial,
    parameters: {if (productId != null) 'product_id': productId},
    debugLog: debugLog,
  );

  void logSubscribe({String? productId, bool debugLog = false}) => logEvent(
    _names.subscribe,
    parameters: {if (productId != null) 'product_id': productId},
    debugLog: debugLog,
  );

  void logPurchase({String? productId, bool debugLog = false}) => logEvent(
    _names.purchase,
    parameters: {if (productId != null) 'product_id': productId},
    debugLog: debugLog,
  );

  void logRefund({String? productId, bool debugLog = false}) => logEvent(
    _names.refund,
    parameters: {if (productId != null) 'product_id': productId},
    debugLog: debugLog,
  );

  void logIapError({String? error, bool debugLog = false}) => logEvent(
    _names.iapError,
    parameters: {if (error != null) 'error': error},
    debugLog: debugLog,
  );

  void logShareApp({String? platform, bool debugLog = false}) => logEvent(
    _names.shareApp,
    parameters: {if (platform != null) 'platform': platform},
    debugLog: debugLog,
  );

  void logRateApp({int? rating, bool debugLog = false}) => logEvent(
    _names.rateApp,
    parameters: {if (rating != null) 'rating': rating},
    debugLog: debugLog,
  );

  void logFeedbackSubmit({bool debugLog = false}) =>
      logEvent(_names.feedbackSubmit, debugLog: debugLog);

  void logAdShow({required String adType, bool debugLog = false}) => logEvent(
    _names.adShow,
    parameters: {'ad_type': adType},
    debugLog: debugLog,
  );

  void logAdClick({required String adType, bool debugLog = false}) => logEvent(
    _names.adClick,
    parameters: {'ad_type': adType},
    debugLog: debugLog,
  );

  void logAdError({
    required String adType,
    String? error,
    bool debugLog = false,
  }) => logEvent(
    _names.adError,
    parameters: {'ad_type': adType, if (error != null) 'error': error},
    debugLog: debugLog,
  );

  void logCustomPurchase({
    required double value,
    required String currency,
    required String itemId,
    required String itemName,
    int quantity = 1,
    bool debugLog = false,
  }) async {
    final params = {
      'value': value,
      'currency': currency,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
    };

    _bloc.add(
      bloc_event.AnalyticsLogEvent(
        AnalyticsEvent(name: 'custom_purchase', parameters: params),
      ),
    );

    if (debugLog) {
      StarterLog.logPurchaseEvent(
        'custom_purchase',
        productId: itemId,
        price: value,
        currency: currency,
        debugLog: true,
      );
    }
  }

  void logScreenView(String screenName, {bool debugLog = false}) {
    _bloc.add(bloc_event.AnalyticsLogScreenView(screenName));
    if (debugLog) {
      StarterLog.d(
        'Screen View: $screenName',
        tag: 'ANALYTICS',
        debugLog: true,
      );
    }
  }
}
