import 'package:flutter/material.dart';
import 'package:storysaver/Constants/CustomColors.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Services/Feedback_Helper/feedback_helper.dart';
import 'package:storysaver/Utils/ShareToApp.dart';
import 'package:storysaver/Utils/checkBusinessMode.dart';
import 'package:storysaver/Widget/HelpModal.dart';
import 'package:storysaver/Widget/svgIcons.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsItem(
            context: context,
            icon: checkIsBusinessMode(context) == false
                ? Icons.business
                : Icons.person,
            label: checkIsBusinessMode(context) == false
                ? 'Business Mode'
                : 'Personal Status',
            onTap: () {
              switchToBusinessMode(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.workspace_premium,
            label: 'Remove Ads',
            onTap: () {
              PresentRevenueCatPayWallIfNeeded();
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.email_outlined,
            label: 'Support',
            onTap: () {
              FeedBackHelper().showContactUsDialog(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.feedback_outlined,
            label: 'Feedback',
            onTap: () {
              FeedBackHelper().showContactUsDialog(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {
              // Add your privacy policy navigation here
              debugPrint('Privacy Policy tapped');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.subscriptions_outlined,
            label: 'Subscription Management',
            onTap: () {
              PresentRevenueCatPayWallIfNeeded();
            },
          ),
          const SizedBox(height: 32),
          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 32),
          _buildSettingsItem(
            context: context,
            icon: Icons.help_outline,
            label: 'Help',
            onTap: () {
              HelpModal().showHelpDialog(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.star_border_outlined,
            label: 'Rate Us',
            onTap: () {
              FeedBackHelper().showFancyRatings(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              shareAppLink(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
