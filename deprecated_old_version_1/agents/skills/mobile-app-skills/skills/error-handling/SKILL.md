---
name: error-handling
description: Centralized error handling using Either pattern, Failure classes, and ErrorHandler
---

# Error Handling

## Overview

All GenRevibes apps use **functional error handling** with the `dartz` package's `Either<Failure, Success>` pattern. Errors are never thrown — they flow as typed `Failure` objects through the architecture.

## Prerequisites

- `dartz: ^0.10.1` in dependencies
- `equatable: ^2.0.7` for Failure equality

## Architecture

```
core/error/
├── error_handler.dart    # Converts exceptions → Failure objects
└── failure.dart          # Failure class hierarchy
```

## Error Flow

```
Exception → ErrorHandler.handle() → Failure → Either<Failure, T> → BLoC State → UI
```

## Failure Types

| Failure | HTTP Code | Message |
|---|---|---|
| `BadRequestFailure` | 400 | Bad request |
| `NotFoundFailure` | 404 | Not found |
| `ServerFailure` | 500 | Internal server error |
| `NoInternetConnectionFailure` | — | No internet connection |
| `ConnectTimeOutFailure` | — | Connection timeout |
| `CancelRequestFailure` | — | Request cancelled |
| `TooManyRequestsFailure` | 429 | Too many requests |
| `NotSubscribedFailure` | 403 | Subscription required |
| `UnexpectedFailure` | — | Unexpected error |

## Implementation

### Failure Base Class

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure() : super(ResponseMessage.serverError);
}
// ... other failure classes
```

### ErrorHandler

```dart
class ErrorHandler implements Exception {
  late Failure failure;

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      failure = _handleDioError(error);
    } else if (error is SocketException) {
      failure = const NoInternetConnectionFailure();
    } else {
      failure = const UnexpectedFailure();
    }
  }
}
```

### Usage in Repository

```dart
@override
Future<Either<Failure, Entity>> getData(String id) async {
  if (!await networkInfo.isConnected) {
    return const Left(NoInternetConnectionFailure());
  }
  try {
    final model = await remoteDataSource.getData(id);
    return Right(model.toDomain());
  } catch (error) {
    return Left(ErrorHandler.handle(error).failure);
  }
}
```

### Usage in BLoC

```dart
final result = await useCase(params);
result.fold(
  (failure) => emit(FeatureError(failure.message)),
  (data) => emit(FeatureSuccess(data)),
);
```

## Interaction Map

- **Every feature** uses this pattern in repositories and BLoCs
- **Network Info** → Checked before API calls
- **UI** → Displays `failure.message` in error states

## Checklist

- [ ] `Failure` base class and subclasses created in `core/error/`
- [ ] `ErrorHandler` created to convert exceptions
- [ ] All repositories return `Either<Failure, T>`
- [ ] All BLoCs handle `.fold()` on results
- [ ] Network connectivity checked before remote calls
