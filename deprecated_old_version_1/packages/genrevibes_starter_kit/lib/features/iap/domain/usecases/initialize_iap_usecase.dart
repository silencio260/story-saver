import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/iap_repository.dart';

class InitializeIapUseCase {
  final IapRepository repository;

  InitializeIapUseCase({required this.repository});

  Future<Either<Failure, void>> call(String apiKey) async {
    return await repository.initialize(apiKey);
  }
}
