import 'dart:io';

import 'package:flutter/services.dart';

import 'failure.dart';
import 'platform_failure.dart';
import 'storage_failure.dart';
import 'unexpected_failure.dart';

class ErrorHandler {
  const ErrorHandler._();

  static Failure handle(Object error) {
    if (error is FileSystemException) {
      return StorageFailure(error.message, cause: error);
    }
    if (error is PlatformException) {
      return PlatformFailure(
        error.message ?? 'A platform operation failed.',
        cause: error,
      );
    }
    return UnexpectedFailure('An unexpected error occurred.', cause: error);
  }
}
