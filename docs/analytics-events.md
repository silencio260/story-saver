# Action and notification analytics

The developer event catalogue lists the app events. Actions emit at the operation outcome rather than from UI success messages. Existing dashboard event names are retained.

| Flow | Events / distinguishing properties |
| --- | --- |
| Manual saves | `save_status_requested`, `save_status` / `save_status_failed`; `source=manual` |
| Bulk saves | `download_all`, per-file save outcome with `source=bulk`, `download_all_completed` with totals |
| Auto-save | `auto_save_started`, per-file save outcome with `source=auto_save`, `auto_save_completed` / `auto_save_failed` |
| Media | Load, delete, clear cache, share request/outcome, viewer and tab changes |
| Settings and permissions | Persisted auto-save/business-mode changes, folder/storage request and outcome, onboarding completion/reset |
| Monetization and support | Ad load/show/click/dismiss/revenue, paywall/restore outcomes, rating decisions/prompts, link success/failure |
| OneSignal | `push_received` for foreground receipt, `push_opened` for tap/action, `push_state_changed` for permission/subscription changes |
| Local notifications | `local_notification_posted`, `local_notification_scheduled`, `local_notification_permission`, `local_notification_cancelled`, `local_notifications_cleared`; all have `success` |
| Local taps | `local_notification_opened` with notification ID and optional action ID; both running app and cold launch |

Clicked notifications include `notification_title`, `notification_body`, and `notification_payload`. OneSignal custom data containing `value` also produces `notification_value`. Push tokens and local media paths are not added by the instrumentation. Local content is carried in a versioned OS payload envelope and unwrapped before navigation listeners receive it; notifications posted before this change may only provide their original payload. Provider parameter-size limits still apply to long content. Notification IDs identify the notification; local IDs can be reused when replacing notifications.

## Delivery semantics

- Notification listeners attach before provider initialization, so launch callbacks have a subscriber.
- Local launch details are checked in the UI isolate. Headless auto-save workers do not process a stale activity launch intent.
- The local `posted` event means the OS show request finished. Check `success`; it is not proof that a notification was visible. A scheduled notification is not counted as delivered.
- The OneSignal Flutter adapter exposes foreground receipts and taps. Background/terminated delivery without a tap has no Dart receipt callback in this adapter. Use OneSignal delivery reporting for that metric. No server webhook or native background receipt extension is configured by this change.
- WorkManager has no app analytics pipeline. It writes events to individual files in application support storage; launch/resume drains those files through Firebase and PostHog. Background events therefore appear after a subsequent app launch/resume. `event_occurred_at` preserves the original time, since the adapters otherwise use SDK ingestion time.
- Entirely failed deliveries are queued for a later launch/resume. Partial provider failures are reported without replaying to providers that already accepted the event. This is not an exactly-once transport or a server delivery acknowledgement. Records older than seven days are discarded when draining.
- AnalyticsBloc checks the delivery report, and pipeline-level failures are now included in the developer event log.

## Device verification (not executed)

1. Save a status from the grid and viewer; confirm exactly one `save_status` with `source=manual` for each successful save.
2. Bulk-download several files and run auto-save; compare per-file results with the completion counts. Run auto-save while the UI is closed, then reopen to verify queued events.
3. Share/delete media, switch tabs and source mode, toggle auto-save, complete onboarding, and grant/deny folder permission. Confirm outcomes match the actual operation.
4. Send a OneSignal push with the app in the foreground; confirm `push_received`. Tap a push while the app is foregrounded, backgrounded, and terminated; confirm `push_opened` once per tap.
5. Post the local test/auto-save notification. Tap it with the app running, backgrounded, and terminated; confirm `local_notification_opened` once per tap. Deny notification permission and inspect the request result without interpreting OS acceptance as visibility.
6. Inspect both Firebase and PostHog, plus the developer event log. Exercise a provider failure and confirm diagnostics report incomplete delivery.

Suggested code validation: `flutter analyze`, then `flutter test test/bootstrap/app_bootstrap_test.dart`. These commands require an explicit request under this repository's agent rules and were not run.

Two supporting changes live inside the `packages/genrevibes_starter_kit` submodule (pipeline diagnostics and local launch handling). Include those changes when distributing the app changes; the parent repository hides dirty submodule content in its default status.
