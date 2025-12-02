import 'package:flutter/material.dart';
import 'package:storysaver/Utils/checkDevelopmentMode.dart';
import 'package:storysaver/Services/AutoSaveService.dart';
import 'package:storysaver/Constants/constant.dart';
import 'package:storysaver/Monetization/IAP/RevenueCat/Services/revenueCatUtil.dart';
import 'package:storysaver/Services/Feedback_Helper/feedback_helper.dart';
import 'package:storysaver/Utils/ShareToApp.dart';
import 'package:storysaver/Utils/checkBusinessMode.dart';
import 'package:storysaver/Widget/HelpModal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storysaver/Screens/Onboarding/onboarding_screen.dart';
import 'package:storysaver/Services/AppRatingService.dart';
import 'package:storysaver/Services/OnboardingManager.dart';
import 'package:storysaver/Monetization/SubscriptionManager.dart';
import 'package:storysaver/Widget/PremiumUpgradeModal.dart';
import 'package:storysaver/Services/analytics_service.dart';

import 'package:storysaver/Provider/getStatusProvider.dart';
import 'package:provider/provider.dart';
import 'package:storysaver/Screens/splash_screen.dart';
import 'package:storysaver/Widget/deleteSavedMediaUtils.dart';
import 'package:storysaver/Provider/savedMediaProvider.dart';
import 'package:storysaver/Services/Notifications/PushNotification.dart';

const canvasColor = Color(0xff154734);

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: canvasColor,
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
            onTap: () async {
              // Check if switching TO Business Mode (currently in Personal Mode)
              if (!checkIsBusinessMode(context)) {
                // Switching to Business Mode - check premium
                final isPremium = SubscriptionManager().isPremium;
                if (!isPremium) {
                  final result = await showPremiumUpgradeModal(
                    context,
                    title: 'Unlock Business Mode',
                    message:
                        'Access WhatsApp Business statuses with Premium! Start your free trial now',
                  );
                  if (result == true) {
                    await RevenueCatService()
                        .PresentRevenueCatPayWallIfNeeded();
                  }
                  return;
                }
              }
              // Allow switch if going to Personal Mode OR user has premium
              switchToBusinessMode(context);
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsItem(
            context: context,
            icon: Icons.workspace_premium,
            label: 'Remove Ads',
            onTap: () async {
              await AnalyticsService.logRemoveAdsClicked();
              RevenueCatService().PresentRevenueCatPayWallIfNeeded();
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
              RevenueCatService().PresentRevenueCatCustomerCenter();
            },
          ),
          const SizedBox(height: 12),
          // Auto Save Feature (Premium Only)
          StatefulBuilder(
            builder: (context, setState) {
              final isPremium = SubscriptionManager().isPremium;
              return FutureBuilder<bool>(
                future: SharedPreferences.getInstance().then((prefs) =>
                    prefs.getBool(AppConstants().IS_AUTO_SAVE_ENABLED) ??
                    false),
                builder: (context, snapshot) {
                  bool isEnabled = snapshot.data ?? false;
                  return SwitchListTile(
                    title: const Text(
                      "Auto Save Statuses",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      "Automatically save new statuses in background (Premium)",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: isEnabled,
                    onChanged: (bool value) async {
                      if (!isPremium) {
                        final result = await showPremiumUpgradeModal(
                          context,
                          title: 'Unlock Auto Save',
                          message:
                              'Automatically save new statuses in the background with Premium! Start your free trial now',
                        );
                        if (result == true) {
                          await RevenueCatService()
                              .PresentRevenueCatPayWallIfNeeded();
                        }
                        return;
                      }
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(
                          AppConstants().IS_AUTO_SAVE_ENABLED, value);
                      setState(() {
                        isEnabled = value;
                      });

                      if (value) {
                        await AnalyticsService.logAutoSaveEnabled();
                        await AutoSaveService.registerPeriodicTask();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Auto Save Enabled (Every 1 hr)")),
                        );
                      } else {
                        await AnalyticsService.logAutoSaveDisabled();
                        await AutoSaveService.cancelAllTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Auto Save Disabled")),
                        );
                      }
                    },
                    activeColor: Colors.green,
                    secondary: const Icon(Icons.download_for_offline,
                        color: Colors.grey),
                  );
                },
              );
            },
          ),

          const Divider(),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          if (DevelopmentModeUtils.checkDevelopmentMode()) ...[
            const Divider(),
            const SizedBox(height: 24), // Added spacing
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text("Developer Options",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            _buildSettingsItem(
              context: context,
              icon: Icons.restart_alt,
              label: 'Reset Onboarding',
              onTap: () async {
                await OnboardingManager.resetOnboarding();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingScreen(forceShow: true)),
                    (route) => false);
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.restore,
              label: 'Reset count to first review popup',
              onTap: () async {
                await AdvancedAppRatingService.resetDownloadCount();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Download count reset to 0")),
                );
              },
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) {
                final subscriptionManager = SubscriptionManager();
                return SwitchListTile(
                  title: const Text(
                    "Dev Premium Access",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    "Bypass paywalls for testing",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: subscriptionManager.debugOverridePremium,
                  onChanged: (bool value) async {
                    await subscriptionManager.toggleDebugPremium(value);
                    setState(() {}); // Rebuild switch
                  },
                  activeColor: Colors.green,
                  secondary: const Icon(Icons.admin_panel_settings,
                      color: Colors.grey),
                );
              },
            ),
            const SizedBox(height: 12),
            // Dev Auto Save Test Mode
            StatefulBuilder(
              builder: (context, setState) {
                return FutureBuilder<bool>(
                  future: SharedPreferences.getInstance().then((prefs) =>
                      prefs.getBool("is_dev_auto_save_test_mode") ?? false),
                  builder: (context, snapshot) {
                    bool isEnabled = snapshot.data ?? false;
                    return SwitchListTile(
                      title: const Text(
                        "Test Auto Save (High Freq)",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        "Polls every 10s (Dev Only)",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: isEnabled,
                      onChanged: (bool value) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(
                            "is_dev_auto_save_test_mode", value);
                        setState(() {
                          isEnabled = value;
                        });

                        if (value) {
                          AutoSaveService.startDevTestMode();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Dev Test Mode Started (10s)")),
                          );
                        } else {
                          AutoSaveService.stopDevTestMode();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Dev Test Mode Stopped")),
                          );
                        }
                      },
                      activeColor: Colors.orange,
                      secondary: const Icon(Icons.speed, color: Colors.grey),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.notifications_active,
              label: 'Test Notification',
              onTap: () async {
                await AutoSaveService.showTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notification sent")),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.notifications_active,
              label: 'Test OneSignal Notification',
              onTap: () async {
                try {
                  final userId = await PushNotification.getUserId();
                  if (userId != null && userId.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('OneSignal User ID'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your OneSignal User ID:'),
                            const SizedBox(height: 8),
                            SelectableText(
                              userId,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'To send a test notification:\n'
                              '1. Go to OneSignal Dashboard\n'
                              '2. Click "Messages" > "New Push"\n'
                              '3. Select "Send to Particular Users"\n'
                              '4. Paste the User ID above',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('User not subscribed to push notifications'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.delete_forever,
              label: 'Delete All Saved & Cache',
              onTap: () async {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Deleting..."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  // await SavedMediaManager().deleteAllSavedContent();
                  await deleteSavedMeidaUtils().deleteAllMedia(
                      context,
                      Provider.of<GetSavedMediaProvider>(context,
                          listen: false),
                      showCompletionSnackBar: false);

                  await Provider.of<GetStatusProvider>(context, listen: false)
                      .clearCacheFromDisk();

                  // Close loading dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("All saved content and cache deleted")),
                  );

                  // Redirect to Splash Screen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SplashScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  // Close loading dialog if error
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting content: $e")),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.cleaning_services,
              label: 'Clear Cache (Fresh Start)',
              onTap: () async {
                await Provider.of<GetStatusProvider>(context, listen: false)
                    .clearCacheFromDisk();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cache cleared")),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
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
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: canvasColor.withOpacity(0.2),
        highlightColor: canvasColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.grey[800],
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[800],
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
