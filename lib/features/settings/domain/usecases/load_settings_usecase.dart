import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class LoadSettingsUseCase extends BaseUseCase<AppSettings, NoParams> {
  const LoadSettingsUseCase({required SettingsBaseRepo repo}) : _repo = repo;

  final SettingsBaseRepo _repo;

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) => _repo.load();
}
