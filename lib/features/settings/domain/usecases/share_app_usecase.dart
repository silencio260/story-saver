import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../repositories/settings_repository.dart';

class ShareAppUseCase extends BaseUseCase<Unit, NoParams> {
  const ShareAppUseCase({required SettingsBaseRepo repo}) : _repo = repo;

  final SettingsBaseRepo _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.shareApp();
}
