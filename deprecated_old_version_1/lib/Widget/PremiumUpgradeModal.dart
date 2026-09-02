import 'package:flutter/material.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Services/analytics_service.dart';

/// Shows a premium upgrade modal dialog with app-consistent green branding
///
/// Returns:
/// - `true` if user wants to upgrade (show paywall)
/// - `false` if user declines (show ad)
/// - `null` if dismissed without choice
Future<bool?> showPremiumUpgradeModal(
  BuildContext context, {
  String title = 'Unlock Premium Downloads',
  String message =
      'Unlock one-click downloads with Premium! Start your free trial now',
  String yesButtonText = 'Start Free Trial',
  String noButtonText = 'Maybe Later',
  bool showMaybeLaterButton = false, // Hidden by default
  Color? primaryColor, // Defaults to app's green
  Color? accentColor, // Defaults to lighter green
  Color? iconColor, // Defaults to gold
}) async {
  // Track analytics
  await AnalyticsService.logViewPaywallModal();
  // Use app colors if not specified
  final primary = primaryColor ?? const Color(CustomColors.PremiumPrimary);
  final accent = accentColor ?? const Color(CustomColors.PremiumAccent);
  final iconGold = iconColor ?? const Color(CustomColors.PremiumGold);

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                primary.withOpacity(0.08),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium icon with gradient
              Container(
                padding: const EdgeInsets.all(16),
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
                ),
                child: Icon(
                  Icons.download_for_offline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800], // Darker gray for better readability
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Benefits list with green check marks
              _buildBenefit(Icons.download_done, 'Unlimited downloads', accent),
              const SizedBox(height: 8),
              _buildBenefit(Icons.block, 'No ads', accent),
              const SizedBox(height: 8),
              _buildBenefit(Icons.speed, 'One-click saves', accent),
              const SizedBox(height: 28),

              // Action buttons
              Column(
                children: [
                  // Yes button - primary action with green theme
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 20, color: iconGold),
                          const SizedBox(width: 8),
                          Text(
                            yesButtonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showMaybeLaterButton) ...[
                    const SizedBox(height: 12),

                    // No button - secondary action
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.grey[850], // Much darker for visibility
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          noButtonText,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[850], // Darker for readability
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildBenefit(IconData icon, String text, Color accentColor) {
  return Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: accentColor,
      ),
      const SizedBox(width: 12),
      Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[800], // Darker for better readability
        ),
      ),
    ],
  );
}
