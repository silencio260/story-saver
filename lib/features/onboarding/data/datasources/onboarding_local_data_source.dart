import 'package:genrevibes_core/genrevibes_core.dart';
import 'package:genrevibes_onboarding/genrevibes_onboarding.dart';

import 'onboarding_base_local_data_source.dart';

export 'onboarding_base_local_data_source.dart';

/// Onboarding completion, over the kit's [OnboardingController].
///
/// Only the completion flag moved. Content, wording, imagery and navigation
/// stay in this app, because those are the parts no two apps in the portfolio
/// share; the flag is the part every one of them gets wrong the same way.
///
/// This used to reach `SharedPreferences` directly for `has_seen_onboarding`,
/// which made it the second writer of that key alongside the legacy
/// `OnboardingManager`. That manager is deleted and the key is now read through
/// the store's legacy-key mapping, so users who already finished onboarding
/// keep their state and are not shown it again.
class OnboardingLocalDataSource implements OnboardingBaseLocalDataSource {
  /// Creates the data source over [controller].
  const OnboardingLocalDataSource({required OnboardingController controller})
      : _controller = controller;

  final OnboardingController _controller;

  @override
  Future<bool> hasCompletedOnboarding() async => _controller.isCompleted;

  @override
  Future<void> completeOnboarding() => _unwrap(_controller.complete());

  @override
  Future<void> resetOnboarding() => _unwrap(_controller.reset());

  /// Keeps the `Future<void>`-that-throws contract this layer is built on.
  Future<void> _unwrap(Future<KitResult<void>> result) async {
    (await result).fold(
      onSuccess: (_) {},
      onFailure: (error) => throw StateError(error.message),
    );
  }
}
