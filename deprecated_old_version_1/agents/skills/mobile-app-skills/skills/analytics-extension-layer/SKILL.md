---
name: analytics-extension-layer
description: Decoupling generic infrastructure from app-specific business tracking using an inheritance-based service architecture.
---

# Analytics Extension Layer

## Overview

A common pitfall in web/app development is mixing generic tracking infrastructure (e.g., ad revenue, standard IAP, app open events) with application-specific business logic (e.g., `chat_message_sent`, `image_studio_download`, `auth_error_code`). 

The **Extension Layer Pattern** separates these concerns by:
1.  Keeping the **Infrastructure** (e.g., `starter_kit`) generic and reusable.
2.  Creating an **App Layer Service** that inherits from the core and adds typed, high-level tracking methods.

## Architecture

### 1. Unified Event Dictionary (`AppAnalyticsEvents`)
Centralizes all app-specific event names as `static const` strings, preventing typos and providing a single source of truth for the dashboard naming convention.

**Example:**
```dart
abstract class AppAnalyticsEvents {
  static const String chatMessageSent = 'chat_message_sent';
  static const String chatModelSwitched = 'chat_model_switched';
  static const String imageGenerationStarted = 'image_generation_started';
}
```

### 2. Extension Service (`AppAnalyticsService`)
Inherits from the base `AnalyticsService`. It wraps the generic `logEvent` with high-level, business-specific methods.

**Core Benefits:**
- **Typed Arguments**: No more passing raw `Map<String, dynamic>` in Blocs or Screens.
- **Internal Inference**: The service can infer metadata (e.g., provider name from a model ID) internally, keeping the presentation layer clean.
- **Global Access**: Usually implemented as a singleton for easy access without dependency injection boilerplate in UI code.

**Example:**
```dart
class AppAnalyticsService extends AnalyticsService {
  AppAnalyticsService(super.bloc);
  static final AppAnalyticsService instance = AppAnalyticsService(StarterKit.analyticsBloc);

  // Business Logic Methods
  void logChatMessageSent({
    required String modelId,
    required bool hasAttachment,
  }) => logEvent(AppAnalyticsEvents.chatMessageSent, parameters: {
    'model_id': modelId,
    'model_provider': _inferProvider(modelId),
    'has_attachment': hasAttachment,
    'platform': Platform.operatingSystem,
  });

  static String _inferProvider(String modelId) => 
      modelId.startsWith('gpt') ? 'openai' : 'other';
}
```

## Implementation Workflow

1.  **Export Core**: Ensure the infrastructure package (`starter_kit`) exports its base `AnalyticsService` and `AnalyticsBloc`.
2.  **Define Names**: Create `AppAnalyticsEvents` with all required constants.
3.  **Create Service**: Implement `AppAnalyticsService` extending the base. Add a singleton `instance`.
4.  **Add Typed Methods**: For every business feature, add a method that takes the minimal required data and enriches it with platform/context metadata.
5.  **Inject into UI**: Replace raw `logEvent` calls in Blocs with typed calls from `AppAnalyticsService.instance`.

## Best Practices

- **Never Hardcode Strings in Blocs**: Always use `AppAnalyticsEvents` constants.
- **Centralize Calculations**: Things like "message length bucket" or "token count rounding" should live in the service layer, not the Bloc.
- **Use Null-Safety for Meta**: Optional parameters (like `latency_ms` or `total_tokens`) should be handled cleanly with logic like `if (val != null) 'key': val`.
- **Inherit Standard Tracking**: By extending the base service, your app-specific service still logs default events like `ad_impression` and `iap_success` without any extra code.

## Standard vs App-Specific Events

Keep reusable starter-kit events in the kit and feature/business events in the app layer.

Starter-kit / shared events:
- `screen_view`
- `app_open`
- `retention_app_opened`
- `retention_day_0_returned`, `retention_day_1_returned`, `retention_day_3_returned`, `retention_day_7_returned`, `retention_day_10_returned`, `retention_day_15_returned`, `retention_day_20_returned`, `retention_day_25_returned`, `retention_day_30_returned`
- `retention_first_open` through `retention_fifth_open`
- `retention_first_session` through `retention_fifth_session`
- `ad_impression`, `ad_revenue`, `ad_click`

App-layer feature events:
- Feature usage such as `search_performed`, `drawer_opened`, `mini_app_open`
- Developer/test events such as `ad_lifecycle`
- Launcher-specific app-management events such as `app_install_event` and `installed_app_removed`

Firebase automatic events that Mixpanel/PostHog do not track automatically should be handled deliberately:
- Mirror `first_open` outside Firebase only once if the exact event name is required.
- Do not try to emit `app_remove` from client code; the app cannot run after uninstall. Use Firebase automatic reporting or backend/push-provider uninstall detection.
- Do not claim `notification_receive`, `in_app_purchase`, or subscription renewal events are tracked unless the actual push/IAP provider callbacks are wired.

## Interactions

- **Blockers**: Avoid using this layer for blocking operations. Logging should always be fire-and-forget.
- **Retention**: Use the `logRetentionEvent` method for user lifecycle milestones (D1, D3, D7) — these often require separate dashboards in tools like Firebase/PostHog.
- **IAP / Ads**: These usually stay in the base `AnalyticsService` as they are universal across most apps.

## Checklist

- [ ] `AppAnalyticsEvents` dictionary created
- [ ] `AppAnalyticsService` extends `AnalyticsService`
- [ ] Feature-specific methods are typed and use internal inference
- [ ] No raw `logEvent` calls exist in the `presentation` layer
- [ ] Platform metadata (OS, App Version) automatically added in service layer
