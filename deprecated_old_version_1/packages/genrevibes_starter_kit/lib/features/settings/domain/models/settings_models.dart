import 'package:flutter/material.dart';

/// Represents a single tile in the settings list
class SettingsTile {
  final String title;
  final IconData? icon; // Simplified for template usage
  final Widget? customLeading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    required this.title,
    this.icon,
    this.customLeading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });
}

/// Represents a section of settings tiles
class SettingsSection {
  final String? title;
  final List<SettingsTile> tiles;

  const SettingsSection({this.title, required this.tiles});
}
