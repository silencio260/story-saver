import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/app_services_repository.dart';
import '../datasources/app_services_data_source.dart';

class AppServicesRepo implements AppServicesBaseRepo {
  const AppServicesRepo({required AppServicesBaseDataSource dataSource})
    : _dataSource = dataSource;

  final AppServicesBaseDataSource _dataSource;

  @override
  Future<Either<Failure, Unit>> initialize() async {
    try {
      await _dataSource.initialize();
      return const Right(unit);
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
