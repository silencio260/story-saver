import 'dart:async';

import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_notifications/genrevibes_notifications.dart';
import 'package:genrevibes_permissions/genrevibes_permissions.dart';
import 'package:genrevibes_storage/genrevibes_storage.dart';

import 'notification_strings.dart';

/// What the home screen should show to get notifications allowed.
enum NotificationPrompt {
  /// Nothing: notifications are allowed, or it is too soon to ask again.
  none,

  /// The system prompt straight away. Only the first ask after install.
  system,

  /// The app's modal first, and the system prompt only if the user agrees.
  modal,
}

/// Schedules the daily notifications once notifications are allowed, and
/// decides when to ask for the permission again.
///
/// The schedule is the app's business: nothing here is shown to the user.
final class DailyReminderService {
  DailyReminderService({
    required this.store,
    required this.scheduler,
    required this.permissions,
    this.clock = const SystemKitClock(),
  });

  final KeyValueStore store;
  final LocalNotificationScheduler scheduler;
  final PermissionProvider permissions;
  final KitClock clock;

  /// Payload on both notifications, so a tap opens Statuses.
  static const payload = 'daily_status_reminders';

  /// How long the modal waits after "Not now" or a denied system prompt.
  static const askAgainAfter = Duration(days: 3);

  static const _channelId = 'story_saver_updates';
  static const _askedKey = 'storysaver.notifications.asked.v1';
  static const _lastAskedKey = 'storysaver.notifications.last_asked_at.v1';
  static const _slots = <({int id, int hour, String body})>[
    (id: 11001, hour: 11, body: NotificationStrings.morningBody),
    (id: 18001, hour: 18, body: NotificationStrings.eveningBody),
  ];

  bool _scheduled = false;
  Future<void>? _syncing;

  /// Schedules both notifications if notifications are allowed.
  ///
  /// Call on launch and resume. The OS keeps the schedule across restarts and
  /// the scheduler moves it on timezone changes, so this only does work once
  /// per launch, or after permission was granted while the app was away.
  Future<void> sync() =>
      _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<void> _sync() async {
    if (_scheduled || !(await _state()).isUsable) return;
    for (final slot in _slots) {
      final result = await scheduler.schedule(
        LocalNotificationRequest(
          id: slot.id,
          content: LocalNotificationContent(
            title: NotificationStrings.title,
            body: slot.body,
            payload: payload,
            channelId: _channelId,
            channelName: NotificationStrings.channelName,
          ),
          schedule: LocalNotificationDaily(hour: slot.hour, minute: 0),
        ),
      );
      if (result.isFailure) return;
    }
    _scheduled = true;
  }

  /// What to show now. Never prompts by itself.
  Future<NotificationPrompt> promptToShow() async {
    final state = await _state();
    if (state.isUsable ||
        state == PermissionState.unknown ||
        state == PermissionState.restricted) {
      return NotificationPrompt.none;
    }
    final asked = (await store.getBool(
      _askedKey,
    )).fold(onSuccess: (value) => value ?? false, onFailure: (_) => true);
    if (!asked && !state.needsSettings) return NotificationPrompt.system;
    final lastAskedMs = (await store.getInt(_lastAskedKey)).fold(
      onSuccess: (value) => value,
      // An unreadable timestamp counts as just asked, so it cannot nag.
      onFailure: (_) => clock.now().millisecondsSinceEpoch,
    );
    if (lastAskedMs != null &&
        clock.now().difference(
              DateTime.fromMillisecondsSinceEpoch(lastAskedMs),
            ) <
            askAgainAfter) {
      return NotificationPrompt.none;
    }
    return NotificationPrompt.modal;
  }

  /// Shows the system prompt, or the app's settings page once Android no
  /// longer shows it, then schedules if notifications were allowed.
  Future<void> requestPermission() async {
    await _markAsked();
    if ((await _state()).needsSettings) {
      // Coming back from Settings resumes the app, which calls [sync].
      await permissions.openSettings();
      return;
    }
    await permissions.request(PermissionKind.notifications);
    await sync();
  }

  /// The user chose "Not now": the modal waits [askAgainAfter].
  Future<void> postpone() => _markAsked();

  Future<void> _markAsked() async {
    await store.setBool(_askedKey, true);
    await store.setInt(_lastAskedKey, clock.now().millisecondsSinceEpoch);
  }

  Future<PermissionState> _state() async =>
      (await permissions.check(PermissionKind.notifications)).fold(
        onSuccess: (state) => state,
        onFailure: (_) => PermissionState.unknown,
      );
}
