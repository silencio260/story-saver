---
name: localization
description: Multi-language support with ARB files, feature-based string classes, and locale switching
---

# Localization

## Overview

All user-facing text is centralized in string classes, organized by feature. This enables easy translation via Flutter's ARB-based localization system.

## Architecture

```
lib/
├── l10n/                          # ARB localization files
│   ├── app_en.arb
│   ├── app_es.arb
│   └── ...
└── src/
    ├── core/utils/
    │   └── app_strings.dart       # App-wide strings
    └── features/{feature}/
        └── presentation/l10n/
            └── {feature}_strings.dart  # Feature strings
```

## Implementation

### String Classes (Phase 1 — No i18n yet)

```dart
class AppStrings {
  static const String appName = "My App";
  static const String download = "Download";
}

class ChatStrings {
  static const String screenTitle = "Chat";
  static const String inputHint = "Type a message...";
  static const String sendButton = "Send";
}
```

### ARB Files (Phase 2 — Full i18n)

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appName": "My App",
  "chatScreenTitle": "Chat",
  "chatInputHint": "Type a message..."
}
```

### Locale Switching

```dart
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  void changeLocale(Locale locale) {
    // Save to SharedPreferences
    emit(locale);
  }
}
```

## Rules

- **Never hardcode strings in UI** — always use string classes
- **One string class per feature** — located in `presentation/l10n/`
- **Descriptive names** — `screenTitle`, `downloadButton`, `errorMessage`

## Interaction Map

- **Settings** → Language selection
- **All features** → Use string classes

## Checklist

- [ ] App-wide strings in `AppStrings`
- [ ] Feature strings in `{Feature}Strings` classes
- [ ] No hardcoded strings in UI
- [ ] ARB files created (when activating i18n)
- [ ] Locale switching via cubit/bloc
