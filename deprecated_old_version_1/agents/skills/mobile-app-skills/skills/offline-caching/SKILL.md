---
name: offline-caching
description: Network-aware repositories, local caching, and connectivity checking
---

# Offline & Caching

## Overview

Repositories check network connectivity before API calls and use local caching for offline support. The `NetworkInfo` abstraction wraps `InternetConnectionChecker`.

## Architecture

```
core/network/
└── network_info.dart          # Abstract + implementation

core/helpers/
└── dio_helper.dart            # HTTP client with timeouts
```

## Implementation

### Network Info

```dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;
  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
```

### Repository Pattern

```dart
@override
Future<Either<Failure, Data>> getData(String id) async {
  if (!await networkInfo.isConnected) {
    // Try local cache first
    final cached = await localDataSource.getCached(id);
    if (cached != null) return Right(cached.toDomain());
    return const Left(NoInternetConnectionFailure());
  }
  try {
    final remote = await remoteDataSource.getData(id);
    await localDataSource.cache(remote);  // Cache for offline
    return Right(remote.toDomain());
  } catch (error) {
    return Left(ErrorHandler.handle(error).failure);
  }
}
### Hive Storage

**Critical Rule**: Use **Manual TypeAdapters** (not `@HiveType` generators).
1. Avoid `hive_generator` and `build_runner`.
2. Extends `TypeAdapter<T>` for each Hive model.
3. Manually implement `read` and `write` with numbered fields.

**Benefits**:
- Faster builds (no codegen).
- Clearer logic and more predictable serialization.
- Less project noise (no `*.g.dart` files).


Use `AppNetworkImage` or `CachedNetworkImage` for consistent image caching across all screens.

## Interaction Map

- **Every feature** → Repositories use `NetworkInfo`
- **Error Handling** → `NoInternetConnectionFailure` returned
- **Chat** → Offline message queue
- **Image Generation** → Cached generated images

## Checklist

- [ ] `NetworkInfo` registered in DI
- [ ] All repositories check connectivity
- [ ] Local caching for frequently accessed data
- [ ] `AppNetworkImage` used for all network images
- [ ] Graceful offline handling in UI
