import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/error/failure.dart';
import '../../domain/repositories/feedback_repository.dart';

/// Feedback Nest API implementation of FeedbackRepository
class FeedbackNestRepositoryImpl implements FeedbackRepository {
  final String apiKey;
  final Dio _dio;

  FeedbackNestRepositoryImpl({
    required this.apiKey,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  @override
  Future<Either<Failure, void>> submitFeedback(
    String text, {
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.feedbacknest.com/v1/feedback',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'message': text,
          if (email != null) 'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      } else {
        return Left(
          UnknownFailure(
            message: 'Failed to submit feedback: ${response.statusCode}',
          ),
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Left(
          NetworkFailure(message: 'Connection timeout. Please try again.'),
        );
      } else if (e.response != null) {
        return Left(
          UnknownFailure(
            message:
                'Failed to submit feedback: ${e.response?.statusCode} - ${e.response?.statusMessage}',
          ),
        );
      } else {
        return Left(UnknownFailure(message: e.message ?? 'Unknown error'));
      }
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
