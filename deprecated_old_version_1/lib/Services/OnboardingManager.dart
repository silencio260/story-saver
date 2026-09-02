import 'package:shared_preferences/shared_preferences.dart';

class OnboardingManager {
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';

  /// Checks if the user has already seen the onboarding screen.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  /// Marks the onboarding as seen.
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, true);
  }

  /// Resets the onboarding status (useful for testing/debugging).
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, false);
  }
}
