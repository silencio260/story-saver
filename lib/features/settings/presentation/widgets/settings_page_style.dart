import 'package:flutter/material.dart';
import 'package:genrevibes_devtools/genrevibes_devtools.dart';
import 'package:genrevibes_feedback_ui/genrevibes_feedback_ui.dart';

import '../../../../core/utils/app_colors.dart';

/// The Settings screen's look, for the kit pages opened from it: contact and
/// feedback, and the developer passcode. Both read from here so they cannot
/// drift apart from Settings or from each other.
abstract final class SettingsPageStyle {
  static const TextStyle _title = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  /// Contact us and Send feedback.
  static const FeedbackPageTheme feedback = FeedbackPageTheme(
    appBarColor: AppColors.settingsCanvas,
    appBarForegroundColor: Colors.white,
    appBarTitleStyle: _title,
    centerTitle: true,
    backgroundColor: Colors.white,
    accentColor: AppColors.settingsCanvas,
  );

  /// The developer passcode page.
  static const DeveloperPasscodeTheme passcode = DeveloperPasscodeTheme(
    appBarColor: AppColors.settingsCanvas,
    appBarForegroundColor: Colors.white,
    appBarTitleStyle: _title,
    centerTitle: true,
    backgroundColor: Colors.white,
    accentColor: AppColors.settingsCanvas,
  );
}
