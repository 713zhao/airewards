/// Enum representing the different authentication providers
/// supported by the AI Rewards System.
/// 
/// This enum is used to track which authentication method
/// was used to create and sign in the user account.
enum AuthProvider {
  /// Google OAuth authentication
  google('google'),
  
  /// Email and password authentication
  email('email'),
  
  /// Apple Sign-In authentication (for future implementation)
  apple('apple'),
  
  /// Anonymous authentication (for guest users)
  anonymous('anonymous');

  const AuthProvider(this.value);
  
  /// String value representation of the provider
  final String value;

  /// Returns the AuthProvider from its string value
  static AuthProvider fromString(String value) {
    switch (value.toLowerCase()) {
      case 'google':
        return AuthProvider.google;
      case 'email':
        return AuthProvider.email;
      case 'apple':
        return AuthProvider.apple;
      case 'anonymous':
        return AuthProvider.anonymous;
      default:
        throw ArgumentError('Unknown auth provider: $value');
    }
  }

  /// Returns a human-readable display name for the provider
  String get displayName {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.email:
        return 'Email';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.anonymous:
        return 'Anonymous';
    }
  }

  /// Returns true if the provider supports profile photos
  bool get supportsProfilePhoto {
    switch (this) {
      case AuthProvider.google:
      case AuthProvider.apple:
        return true;
      case AuthProvider.email:
      case AuthProvider.anonymous:
        return false;
    }
  }

  /// Returns true if the provider requires email verification
  bool get requiresEmailVerification {
    switch (this) {
      case AuthProvider.email:
        return true;
      case AuthProvider.google:
      case AuthProvider.apple:
      case AuthProvider.anonymous:
        return false;
    }
  }

  /// Returns true if the provider supports display names by default
  bool get supportsDisplayName {
    switch (this) {
      case AuthProvider.google:
      case AuthProvider.apple:
        return true;
      case AuthProvider.email:
      case AuthProvider.anonymous:
        return false;
    }
  }

  @override
  String toString() => value;
}