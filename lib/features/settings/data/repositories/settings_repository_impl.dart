import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepo implements SettingsBaseRepo {
  const SettingsRepo({required SettingsBaseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final SettingsBaseLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, AppSettings>> load() =>
      _settings(_localDataSource.loadAutoSave);

  @override
  Future<Either<Failure, AppSettings>> setAutoSave(bool enabled) =>
      _settings(() => _localDataSource.setAutoSave(enabled));

  @override
  Future<Either<Failure, Unit>> shareApp() => _unit(_localDataSource.shareApp);

  @override
  Future<Either<Failure, Unit>> rateApp() => _unit(_localDataSource.rateApp);

  @override
  Future<Either<Failure, Unit>> contactSupport() =>
      _unit(_localDataSource.contactSupport);

  Future<Either<Failure, AppSettings>> _settings(
    Future<bool> Function() operation,
  ) async {
    try {
      return Right(AppSettings(autoSaveEnabled: await operation()));
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Unit>> _unit(Future<void> Function() operation) async {
    try {
      await operation();
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
