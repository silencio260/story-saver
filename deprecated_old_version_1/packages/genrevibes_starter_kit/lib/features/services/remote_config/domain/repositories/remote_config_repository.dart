import 'package:dartz/dartz.dart';
import 'package:genrevibes_starter_kit/core/error/failure.dart';

/// Repository for fetching remote configuration values
abstract class RemoteConfigRepository {
  /// Set default values
  Future<void> setDefaults(Map<String, dynamic> defaults);

  /// Fetch and activate the latest values
  Future<Either<Failure, void>> fetchAndActivate();

  /// Get a string value
  String getString(String key);

  /// Get a boolean value
  bool getBool(String key);

  /// Get an integer value
  int getInt(String key);

  /// Get a double value
  double getDouble(String key);
}
