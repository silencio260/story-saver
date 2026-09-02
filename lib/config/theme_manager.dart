import 'package:flutter/material.dart';

import '../core/utils/app_colors.dart';

class ThemeManager {
  const ThemeManager._();

  static ThemeData get lightTheme => ThemeData(
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.fixed),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    useMaterial3: true,
  );
}
