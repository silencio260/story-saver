abstract class OnboardingBaseLocalDataSource {
  Future<bool> hasCompletedOnboarding();

  Future<void> completeOnboarding();

  Future<void> resetOnboarding();
}
