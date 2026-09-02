import 'package:dartz/dartz.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genrevibes_starter_kit/core/error/failure.dart';
import 'package:genrevibes_starter_kit/core/utils/starter_log.dart';
import '../../domain/repositories/app_rating_repository.dart';
import '../../../../ads/domain/services/ad_suppression_manager.dart';

class AppRatingRepositoryImpl implements AppRatingRepository {
  final InAppReview _inAppReview = InAppReview.instance;
  final SharedPreferences _prefs;

  AppRatingRepositoryImpl(this._prefs);

  static const String _keySessionCount = 'app_rating_session_count';
  static const String _keyMessagesSent = 'app_rating_messages_sent';

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      // Increment session count
      final currentSessions = _prefs.getInt(_keySessionCount) ?? 0;
      await _prefs.setInt(_keySessionCount, currentSessions + 1);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEligibility() async {
    try {
      final sessionCount = _prefs.getInt(_keySessionCount) ?? 0;
      final messagesSent = _prefs.getInt(_keyMessagesSent) ?? 0;

      // Thresholds: 3 sessions AND 5 messages
      final isEligible = sessionCount >= 3 && messagesSent >= 5;

      StarterLog.d('Check App Rating Eligibility', tag: 'RATING', values: {
        'Sessions': sessionCount,
        'Messages': messagesSent,
        'Eligible': isEligible
      });

      return Right(isEligible);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        // Suppress ads while prompt is showing
        await AdSuppressionManager.instance.withAdsSuppressed(
          reason: 'app_rating',
          action: () => _inAppReview.requestReview(),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> incrementMessagesSent() async {
    final current = _prefs.getInt(_keyMessagesSent) ?? 0;
    await _prefs.setInt(_keyMessagesSent, current + 1);
  }
}
