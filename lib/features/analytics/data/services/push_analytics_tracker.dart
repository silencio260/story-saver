import 'dart:async';
import 'dart:convert';

import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';

import 'analytics_service.dart';

/// One runtime owner for push events and persisted subscription transitions.
/// Local reminders have their own campaign, permission and post events.
final class PushAnalyticsTracker {
  PushAnalyticsTracker({required this.provider, required this.store});

  final PushNotificationProvider provider;
  final KeyValueStore store;
  static const _stateKey = 'storysaver.push.analytics_state.v1';
  StreamSubscription<PushEvent>? _subscription;
  Future<void> _queue = Future.value();
  Map<String, dynamic>? _previous;
  bool _loaded = false;
  bool _closed = false;
  int _revision = 0;
  final Set<String> _opens = {};

  void start() {
    _subscription ??= provider.events.listen((event) {
      switch (event) {
        case PushStateChanged(:final reason, :final state):
          _revision++;
          _enqueue(() => _recordState(state, reason));
        case PushMessageReceived(:final message):
          unawaited(
            AnalyticsService.track('push_received', {
              'provider': provider.providerId,
              'notification_id': message.messageId,
              'app_state': 'foreground',
            }),
          );
        case PushMessageOpened(:final message):
          final key = '${message.messageId}:${message.actionId ?? ''}';
          if (!_opens.add(key)) return;
          if (_opens.length > 100) _opens.remove(_opens.first);
          unawaited(
            AnalyticsService.track('push_opened', {
              'provider': provider.providerId,
              'notification_id': message.messageId,
              if (message.actionId?.isNotEmpty == true)
                'action_id': message.actionId,
            }),
          );
      }
    });
  }

  void _enqueue(Future<void> Function() action) {
    _queue = _queue
        .then((_) async {
          if (!_closed) await action();
        })
        .catchError((Object _) {
          unawaited(
            AnalyticsService.track('push_state_check_failed', {
              'provider': provider.providerId,
            }),
          );
        });
  }

  Future<void> refresh({String reason = 'resume'}) async {
    final revision = _revision;
    try {
      final result = await provider.getSubscriptionState().timeout(
        const Duration(seconds: 5),
      );
      if (_closed || revision != _revision) return;
      result.fold(
        onSuccess: (state) => _enqueue(() => _recordState(state, reason)),
        onFailure:
            (_) => unawaited(
              AnalyticsService.track('push_state_check_failed', {
                'provider': provider.providerId,
              }),
            ),
      );
    } catch (_) {
      if (!_closed) {
        unawaited(
          AnalyticsService.track('push_state_check_failed', {
            'provider': provider.providerId,
          }),
        );
      }
    }
  }

  Future<void> _recordState(PushSubscriptionState state, String reason) async {
    if (!_loaded) {
      final saved = await store.getString(_stateKey);
      final raw = saved.fold(
        onSuccess: (value) => value,
        onFailure: (_) => null,
      );
      try {
        if (raw != null) _previous = jsonDecode(raw) as Map<String, dynamic>;
      } on Object {
        _previous = null;
      }
      _loaded = true;
    }
    if (_closed) return;
    final current = <String, dynamic>{
      'permission': state.permission.name,
      'has_permission': state.hasPermission,
      'opted_in': state.optedIn,
      'deliverable': state.isDeliverable,
      'has_subscription_id': state.subscriptionId?.isNotEmpty == true,
      'has_push_token': state.pushToken?.isNotEmpty == true,
    };
    final previous = _previous;
    if (previous != null &&
        current.keys.every((key) => current[key] == previous[key]))
      return;
    final fields = <String, Object?>{
      'provider': state.providerId,
      'reason': reason,
      'observation': previous == null ? 'initial' : 'transition',
      ...current,
    };
    await AnalyticsService.track('push_state_changed', fields);
    // An initial denied/unknown snapshot is not a newly revoked permission.
    if (previous != null) {
      if (previous['permission'] != current['permission']) {
        await AnalyticsService.track('push_permission_changed', {
          ...fields,
          'previous_permission': previous['permission'],
        });
      }
      if (previous['has_permission'] == true &&
          state.permission == PushPermissionStatus.denied) {
        await AnalyticsService.track('push_permission_revoked', fields);
      }
      if (previous['opted_in'] == true && state.optedIn == false) {
        await AnalyticsService.track('push_unsubscribed', fields);
      } else if (previous['opted_in'] == false && state.optedIn == true) {
        await AnalyticsService.track('push_subscribed', fields);
      }
    }
    // Never persist IDs, tokens or payload content in analytics state.
    _previous = current;
    final saved = await store.setString(_stateKey, jsonEncode(current));
    if (saved.isFailure) {
      unawaited(
        AnalyticsService.track('push_state_persistence_failed', {
          'provider': state.providerId,
        }),
      );
    }
  }

  Future<void> dispose() async {
    _closed = true;
    await _subscription?.cancel();
    await _queue;
  }
}
