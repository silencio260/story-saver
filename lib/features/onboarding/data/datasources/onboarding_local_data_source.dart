import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_base_local_data_source.dart';

export 'onboarding_base_local_data_source.dart';

class OnboardingLocalDataSource implements OnboardingBaseLocalDataSource {
  const OnboardingLocalDataSource();

  static const String _key = 'has_seen_onboarding';

  @override
  Future<bool> hasCompletedOnboarding() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> completeOnboarding() async {
    await (await SharedPreferences.getInstance()).setBool(_key, true);
  }

  @override
  Future<void> resetOnboarding() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}
