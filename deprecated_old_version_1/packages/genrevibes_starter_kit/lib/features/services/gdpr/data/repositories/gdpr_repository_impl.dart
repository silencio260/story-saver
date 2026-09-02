import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:genrevibes_starter_kit/core/error/failure.dart';
import 'package:genrevibes_starter_kit/core/utils/starter_log.dart';
import '../../domain/repositories/gdpr_repository.dart';

class GdprRepositoryImpl implements GdprRepository {
  final ConsentDebugSettings? debugSettings;

  GdprRepositoryImpl({this.debugSettings});

  @override
  Future<Either<Failure, void>> requestConsent() async {
    try {
      final params = ConsentRequestParameters(
        consentDebugSettings: debugSettings,
      );
      final completer = Completer<Either<Failure, void>>();

      StarterLog.d('Requesting Consent Info Update...', tag: 'GDPR');

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          final isFormAvailable =
              await ConsentInformation.instance.isConsentFormAvailable();
          final status = await ConsentInformation.instance.getConsentStatus();

          StarterLog.i('GDPR Update Success', tag: 'GDPR', values: {
            'Available': isFormAvailable,
            'Status': status.name,
          });

          if (isFormAvailable && status == ConsentStatus.required) {
            _showConsentForm(completer);
          } else {
            completer.complete(const Right(null));
          }
        },
        (FormError error) {
          StarterLog.e('GDPR Consent Info Update Error',
              tag: 'GDPR', error: error.message);
          completer.complete(Left(ServerFailure(message: error.message)));
        },
      );

      return await completer.future;
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  void _showConsentForm(Completer<Either<Failure, void>> completer) {
    StarterLog.d('Loading Consent Form...', tag: 'GDPR');
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          StarterLog.i('Showing Consent Form...', tag: 'GDPR');
          consentForm.show(
            (FormError? error) {
              if (error != null) {
                StarterLog.e('GDPR Consent Form Show Error',
                    tag: 'GDPR', error: error.message);
                completer.complete(Left(ServerFailure(message: error.message)));
              } else {
                // Form dismissed without error. Do NOT call requestConsent()
                // again — if the user dismissed while still `required`, that
                // would re-show the form in a loop. Complete successfully and
                // let callers read isConsentGiven() for the final state.
                StarterLog.i('Consent Form Dismissed', tag: 'GDPR');
                completer.complete(const Right(null));
              }
            },
          );
        } else {
          completer.complete(const Right(null));
        }
      },
      (FormError error) {
        StarterLog.e('GDPR Consent Form Load Error',
            tag: 'GDPR', error: error.message);
        completer.complete(Left(ServerFailure(message: error.message)));
      },
    );
  }

  @override
  Future<Either<Failure, bool>> isConsentGiven() async {
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      return Right(status == ConsentStatus.obtained);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetConsent() async {
    try {
      StarterLog.w('Resetting Consent State...', tag: 'GDPR');
      await ConsentInformation.instance.reset();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
