import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:genrevibes_starter_kit/starter_kit.dart';

/// Shows a premium upgrade modal dialog with app-consistent emerald branding
/// 
/// Returns:
/// - `true` if user wants to upgrade (show paywall)
/// - `false` if user declines (show ad)
/// - `null` if dismissed without choice
Future<bool?> showPremiumUpgradeModal(
  BuildContext context, {
  String title = 'Unlock Pro Features',
  String message = 'Unlock all elite tools and unlimited AI responses with Pro! Start your free trial now',
  String yesButtonText = 'Start Free Trial',
  String noButtonText = 'Maybe Later',
  bool showMaybeLaterButton = true,
  Color? primaryColor,
  Color? accentColor,
  Color? iconColor,
  IconData icon = Icons.auto_awesome_rounded,
}) async {
  // Track analytics
  StarterKit.analytics.logEvent('view_premium_modal');

  // Use app emerald colors if not specified
  final primary = primaryColor ?? const Color(0xFF10B981); // Emerald
  final accent = accentColor ?? const Color(0xFF34D399);   // Lighter Emerald
  final iconGold = iconColor ?? const Color(0xFFFFD700);    // Gold

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium icon with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          primary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.7),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Action buttons
                  Column(
                    children: [
                      // Yes button
                      Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [primary, accent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stars_rounded, size: 24, color: iconGold),
                              const SizedBox(width: 12),
                              Text(
                                yesButtonText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (showMaybeLaterButton) ...[
                        const SizedBox(height: 16),
                        // No button
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            noButtonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
