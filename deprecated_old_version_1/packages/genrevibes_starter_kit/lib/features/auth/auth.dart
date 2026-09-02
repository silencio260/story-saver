/// Authentication feature for Firebase Auth integration
///
/// Provides anonymous, email/password, Google, and Apple sign-in
/// with account linking support.
library;

// Domain - Entities
export 'domain/entities/auth_provider.dart';
export 'domain/entities/user_entity.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';

// Domain - Use Cases
export 'domain/usecases/auth_usecases.dart';

// Data - Models
export 'data/models/user_model.dart';

// Data - Data Sources
export 'data/datasources/auth_remote_data_source.dart';

// Data - Repositories

// Presentation - BLoC
export 'presentation/bloc/auth_bloc.dart';

// Dependency Injection
export 'auth_injector.dart';
