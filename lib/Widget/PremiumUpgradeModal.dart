import 'package:flutter/material.dart';

/// Shows a premium upgrade modal dialog
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
}) async {
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
                Colors.amber.shade50,
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
                      Colors.amber.shade400,
                      Colors.orange.shade600,
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
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Benefits list
              _buildBenefit(Icons.download_done, 'Unlimited downloads'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.block, 'No ads'),
              const SizedBox(height: 8),
              _buildBenefit(Icons.speed, 'One-click saves'),
              const SizedBox(height: 28),

              // Action buttons
              Column(
                children: [
                  // Yes button - primary action
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            yesButtonText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        foregroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        noButtonText,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildBenefit(IconData icon, String text) {
  return Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: Colors.green.shade600,
      ),
      const SizedBox(width: 12),
      Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[700],
        ),
      ),
    ],
  );
}
