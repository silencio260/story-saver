import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/product.dart';
import '../repositories/iap_repository.dart';

/// Get available products use case
class GetProductsUseCase extends BaseUseCase<List<Product>, List<String>> {
  final IapRepository repository;

  GetProductsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<Product>>> call(List<String> productIds) async {
    return await repository.getProducts(productIds);
  }
}
