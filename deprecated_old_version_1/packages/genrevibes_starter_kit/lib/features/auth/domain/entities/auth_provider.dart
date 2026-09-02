/// Authentication provider types
enum AuthProvider {
  anonymous,
  email,
  google,
  apple,
}

/// Extension to convert AuthProvider to string
extension AuthProviderExtension on AuthProvider {
  String get value {
    switch (this) {
      case AuthProvider.anonymous:
        return 'anonymous';
      case AuthProvider.email:
        return 'email';
      case AuthProvider.google:
        return 'google';
      case AuthProvider.apple:
        return 'apple';
    }
  }

  static AuthProvider fromString(String value) {
    switch (value.toLowerCase()) {
      case 'anonymous':
        return AuthProvider.anonymous;
      case 'email':
        return AuthProvider.email;
      case 'google':
        return AuthProvider.google;
      case 'apple':
        return AuthProvider.apple;
      default:
        return AuthProvider.anonymous;
    }
  }
}
