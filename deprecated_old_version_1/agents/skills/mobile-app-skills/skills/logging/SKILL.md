---
name: logging
description: A centralized, styled logging system for real-time observability and debugging.
---

# Logging System (StarterLog)

The logging system is a core utility provided in the `starter_kit` to ensure high observability and beautiful debugging outputs in the console. It uses the `logger` package to provide framed, color-coded, and emoji-enhanced logs.

## 📁 Key File
- `lib/core/utils/starter_log.dart`

## 🏷️ Standard Tags
Use these tags to stay consistent with the existing logging structure:
- `[CONFIG]` - Remote Config fetch/activation events.
- `[ADS]` - Advertisements (loading, showing, events).
- `[IAP]` - In-App Purchases (validation, receipts, events).
- `[ANALYTICS]` - Direct analytics firing events.
- `[GDPR]` - Consent status and form updates.
- `[DATABASE]` - Firestore/Storage interactions.

## 🚀 Usage

### 1. Basic Debug Log
```dart
StarterLog.d('Something happened');
```

### 2. Tagged Log with Values
```dart
StarterLog.i(
  'Fetch Success',
  tag: 'CONFIG',
  values: {
    'count': 5,
    'source': 'remote',
    'duration': '342ms',
  },
);
```

### 3. Error Logging
```dart
try {
  // logic
} catch (e, stack) {
  StarterLog.e('Failed to load data', tag: 'FEATURE', error: e, stackTrace: stack);
}
```

### 4. Specialized Loggers
There are pre-defined helper methods for common events:
- `StarterLog.logAdEvent(...)`
- `StarterLog.logPurchaseEvent(...)`
- `StarterLog.logAnalyticsEvent(...)`
- `StarterLog.logRemoteConfigEvent(...)`

## 🎨 Best Practices
- **Never use `print()`** directly; always use `StarterLog`.
- **Use tags** for easy filtering in the terminal.
- **Pass structured values** via the `values` map for easier reading (it will auto-format them into a frame).
- **Include StackTrace** for critical errors in `StarterLog.e`.
