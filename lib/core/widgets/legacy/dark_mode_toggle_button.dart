import 'package:flutter/material.dart';

/// Compatibility form of the original unused theme button.
class DarkModeToggleButton extends StatelessWidget {
  const DarkModeToggleButton({this.onToggle, super.key});

  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      iconSize: 11,
      icon: Icon(
        isDarkMode ? Icons.light_mode : Icons.dark_mode,
        color: Colors.white,
      ),
      onPressed: onToggle,
      tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
