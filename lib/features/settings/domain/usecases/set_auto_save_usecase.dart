import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class SetAutoSaveUseCase extends BaseUseCase<AppSettings, bool> {
  const SetAutoSaveUseCase({required SettingsBaseRepo repo}) : _repo = repo;

  final SettingsBaseRepo _repo;

  @override
  Future<Either<Failure, AppSettings>> call(bool enabled) =>
      _repo.setAutoSave(enabled);
}
