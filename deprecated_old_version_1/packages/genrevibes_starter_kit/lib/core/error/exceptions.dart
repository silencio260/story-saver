/// Base exception class for StarterKit
class StarterKitException implements Exception {
  final String message;
  final dynamic originalError;

  const StarterKitException({required this.message, this.originalError});

  @override
  String toString() => 'StarterKitException: $message';
}

/// Network exception
class NetworkException extends StarterKitException {
  const NetworkException({super.message = 'Network error'});
}

/// Server exception
class ServerException extends StarterKitException {
  final int? statusCode;

  const ServerException({super.message = 'Server error', this.statusCode});
}

/// Configuration exception
class ConfigurationException extends StarterKitException {
  const ConfigurationException({super.message = 'Configuration error'});
}

/// Purchase exception
class PurchaseException extends StarterKitException {
  const PurchaseException({required super.message});
}

/// Ad exception
class AdException extends StarterKitException {
  const AdException({required super.message});
}
