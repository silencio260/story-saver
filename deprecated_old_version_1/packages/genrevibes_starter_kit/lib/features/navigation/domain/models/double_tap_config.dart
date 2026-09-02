import 'package:flutter/material.dart';

/// Configuration model for Double Tap to Exit widget
class DoubleTapExitConfig {
  /// Dialog title text
  final String dialogTitle;
  
  /// Dialog content/body text
  final String dialogContent;
  
  /// Confirm button text (typically "Yes" or "Exit")
  final String confirmButtonText;
  
  /// Cancel button text (typically "No" or "Cancel")
  final String cancelButtonText;
  
  /// Duration for double tap timeout (default: 2 seconds)
  final Duration doubleTapDuration;
  
  /// Dialog title text style
  final TextStyle? titleTextStyle;
  
  /// Dialog content text style
  final TextStyle? contentTextStyle;
  
  /// Confirm button text style
  final TextStyle? confirmButtonTextStyle;
  
  /// Cancel button text style
  final TextStyle? cancelButtonTextStyle;
  
  /// Dialog background color
  final Color? dialogBackgroundColor;
  
  /// Confirm button color
  final Color? confirmButtonColor;
  
  /// Cancel button color
  final Color? cancelButtonColor;
  
  /// Dialog title color
  final Color? titleColor;
  
  /// Dialog content color
  final Color? contentColor;
  
  /// Confirm button text color
  final Color? confirmButtonTextColor;
  
  /// Cancel button text color
  final Color? cancelButtonTextColor;
  
  /// Dialog shape/border radius
  final ShapeBorder? dialogShape;
  
  /// SnackBar message for double tap (shown when user taps back twice quickly)
  final String? snackBarMessage;
  
  /// SnackBar text style
  final TextStyle? snackBarTextStyle;
  
  /// SnackBar background color
  final Color? snackBarBackgroundColor;
  
  /// SnackBar text color
  final Color? snackBarTextColor;
  
  /// SnackBar duration
  final Duration snackBarDuration;
  
  const DoubleTapExitConfig({
    this.dialogTitle = 'Exit App',
    this.dialogContent = 'Are you sure you want to leave?',
    this.confirmButtonText = 'Yes',
    this.cancelButtonText = 'No',
    this.doubleTapDuration = const Duration(seconds: 2),
    this.titleTextStyle,
    this.contentTextStyle,
    this.confirmButtonTextStyle,
    this.cancelButtonTextStyle,
    this.dialogBackgroundColor,
    this.confirmButtonColor,
    this.cancelButtonColor,
    this.titleColor = Colors.white,
    this.contentColor = Colors.white,
    this.confirmButtonTextColor = Colors.white,
    this.cancelButtonTextColor = Colors.white,
    this.dialogShape,
    this.snackBarMessage = 'Tap back again to exit',
    this.snackBarTextStyle,
    this.snackBarBackgroundColor,
    this.snackBarTextColor,
    this.snackBarDuration = const Duration(seconds: 2),
  });
}
