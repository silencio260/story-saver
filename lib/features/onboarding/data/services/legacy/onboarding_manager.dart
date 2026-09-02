import 'package:shared_preferences/shared_preferences.dart';

class OnboardingManager {
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_keyHasSeenOnboarding) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keyHasSeenOnboarding, true);
  }

  static Future<void> resetOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keyHasSeenOnboarding, false);
  }
}
