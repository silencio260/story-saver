import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genrevibes_crash/genrevibes_crash.dart';
import 'package:storysaver/features/analytics/data/services/analytics_service.dart';

/// Forwards bloc failures to the crash reporter.
///
/// The previous observer printed the error and stopped there, so every failure
/// inside a bloc was invisible in production. A bloc error does not reach
/// `FlutterError.onError` or the guarded zone — bloc catches it and routes it
/// here — so without this the reporter never learns about it at all.
///
/// Reported as non-fatal: a bloc error is handled, the widget tree survives it,
/// and treating it as a crash would misstate the crash-free rate.
class AppBlocObserver extends BlocObserver {
  /// Creates an observer that reports through [crash].
  const AppBlocObserver(this._crash);

  final CrashCoordinator _crash;

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (bloc.runtimeType.toString() != 'AnalyticsBloc') {
      unawaited(
        AnalyticsService.track('app_bloc_failed', {
          'bloc': bloc.runtimeType.toString(),
        }),
      );
    }
    if (kDebugMode) debugPrint('${bloc.runtimeType}: $error');
    unawaited(
      _crash.report(
        CrashReport(
          error: error,
          stackTrace: stackTrace,
          reason: '${bloc.runtimeType} failed',
          fatal: false,
          source: CrashSource.bloc,
        ),
      ),
    );
    super.onError(bloc, error, stackTrace);
  }
}
