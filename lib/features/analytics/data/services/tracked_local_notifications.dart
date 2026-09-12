import 'dart:async';

import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';

import 'analytics_service.dart';

/// Tracks OS requests and interactions without claiming confirmed display.
final class TrackedLocalNotifications implements LocalNotificationScheduler {
  TrackedLocalNotifications(this._delegate) {
    _subscription = _delegate.interactions.listen((interaction) {
      unawaited(
        AnalyticsService.track('local_notification_opened', {
          'provider': 'local',
          if (interaction.title != null)
            'notification_title': interaction.title,
          if (interaction.body != null) 'notification_body': interaction.body,
          if (interaction.payload != null)
            'notification_payload': interaction.payload,
          if (interaction.notificationId != null)
            'notification_id': interaction.notificationId,
          if (interaction.actionId?.isNotEmpty == true)
            'action_id': interaction.actionId,
        }),
      );
    });
  }

  final LocalNotificationScheduler _delegate;
  late final StreamSubscription<LocalNotificationInteraction> _subscription;

  @override
  String get moduleId => _delegate.moduleId;
  @override
  ModuleHealth get health => _delegate.health;
  @override
  Stream<ModuleHealth> get healthChanges => _delegate.healthChanges;
  @override
  Stream<LocalNotificationInteraction> get interactions =>
      _delegate.interactions;
  @override
  Future<KitResult<void>> initialize() => _delegate.initialize();

  Future<KitResult<T>> _record<T>(
    String name,
    Future<KitResult<T>> Function() action,
    Map<String, Object?> fields,
  ) async {
    final result = await action();
    await AnalyticsService.track(name, {
      'provider': 'local',
      ...fields,
      'success': result.isSuccess,
      ...result.fold<Map<String, Object?>>(
        onSuccess: (value) => value is bool ? {'granted': value} : {},
        onFailure: (error) => {'error_code': error.code.name},
      ),
    });
    return result;
  }

  @override
  Future<KitResult<bool>> requestPermission() =>
      _record('local_notification_permission', _delegate.requestPermission, {});
  @override
  Future<KitResult<void>> show(int id, LocalNotificationContent content) =>
      _record('local_notification_posted', () => _delegate.show(id, content), {
        'notification_id': id,
        'channel_id': content.channelId,
      });
  @override
  Future<KitResult<void>> schedule(LocalNotificationRequest request) => _record(
    'local_notification_scheduled',
    () => _delegate.schedule(request),
    {'notification_id': request.id, 'channel_id': request.content.channelId},
  );
  @override
  Future<KitResult<List<PendingLocalNotification>>> pending() =>
      _delegate.pending();
  @override
  Future<KitResult<void>> cancel(int id) => _record(
    'local_notification_cancelled',
    () => _delegate.cancel(id),
    {'notification_id': id},
  );
  @override
  Future<KitResult<void>> cancelAll() =>
      _record('local_notifications_cleared', _delegate.cancelAll, {});
  @override
  Future<KitResult<void>> dispose() async {
    await _subscription.cancel();
    return _delegate.dispose();
  }
}
