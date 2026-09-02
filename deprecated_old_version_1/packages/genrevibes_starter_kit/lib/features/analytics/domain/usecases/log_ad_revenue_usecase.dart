import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/ad_revenue_event.dart';
import '../repositories/analytics_repository.dart';

class LogAdRevenueUseCase implements BaseUseCase<void, AdRevenueEvent> {
  final AnalyticsRepository repository;

  LogAdRevenueUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(AdRevenueEvent params) async {
    return await repository.logAdRevenue(params);
  }
}
