import 'package:flutter/material.dart';

/// Model representing a single page in the Onboarding flow
class OnboardingPageModel {
  final String title;
  final String description;
  final String? imagePath;
  final Widget? customWidget;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    this.imagePath,
    this.customWidget,
    this.backgroundColor,
    this.titleColor,
    this.descriptionColor,
  });
}
