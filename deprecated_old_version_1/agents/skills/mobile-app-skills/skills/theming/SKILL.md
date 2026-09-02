---
name: theming
description: Dark/light mode, design tokens, color constants, text styles, and theme configuration
---

# Theming

## Overview

Theming centralizes all visual design tokens (colors, fonts, text styles) and provides dark/light mode support through Flutter's `ThemeData`.

## Architecture

```
core/utils/
├── app_colors.dart        # Color constants
├── font_manager.dart      # Font families, sizes, weights
└── styles_manager.dart    # Text style generators

config/
└── theme_manager.dart     # ThemeData configuration
```

## Implementation

### Colors

```dart
class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  // Dark mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
}
```

### Theme Manager

```dart
class ThemeManager {
  static ThemeData lightTheme() => ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    // ... complete theme
  );

  static ThemeData darkTheme() => ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
  );
}
```

### Wire in MyApp

```dart
MaterialApp(
  theme: ThemeManager.lightTheme(),
  darkTheme: ThemeManager.darkTheme(),
  themeMode: ThemeMode.system, // or managed via BLoC
)
```

## Interaction Map

- **Settings** → Dark mode toggle
- **All screens** → Use `AppColors`, `StylesManager` consistently

## Checklist

- [ ] `AppColors` defined with light and dark variants
- [ ] `FontManager` with font sizes and weights
- [ ] `StylesManager` for reusable text styles
- [ ] `ThemeManager` with light and dark themes
- [ ] `MaterialApp` uses both themes
- [ ] All UI uses design tokens, no hardcoded colors/styles
