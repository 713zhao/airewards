import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/usecases/usecase.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/value_objects.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';

/// Parameters for the Sign In with Email use case.
/// 
/// This class encapsulates all the required data for email/password
/// authentication and provides validation.
class SignInWithEmailParams {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  /// Create validated params with proper email and password validation.
  /// 
  /// Returns [Either<ValidationFailure, SignInWithEmailParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [SignInWithEmailParams] if validation succeeds
  static Either<ValidationFailure, SignInWithEmailParams> create({
    required String email,
    required String password,
  }) {
    try {
      // Validate email format
      final emailValue = Email(email);
      
      // Validate password (basic validation for sign-in, not strength)
      if (password.trim().isEmpty) {
        return Either.left(ValidationFailure.requiredField('Password'));
      }

      return Either.right(SignInWithEmailParams(
        email: emailValue.value,
        password: password,
      ));
    } on ArgumentError catch (e) {
      if (e.message.toString().contains('email')) {
        return Either.left(ValidationFailure.invalidEmail());
      }
      return Either.left(ValidationFailure(e.message.toString()));
    }
  }

  @override
  String toString() => 'SignInWithEmailParams(email: $email, password: [HIDDEN])';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SignInWithEmailParams &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode;
}

/// Use case for signing in with email and password.
/// 
/// This use case handles the business logic for email/password authentication,
/// including validation, error handling, and security considerations.
/// It follows the single responsibility principle by focusing solely on
/// email/password sign-in functionality.
/// 
/// Business rules:
/// - Email must be in valid format
/// - Password cannot be empty
/// - Account must exist and be active
/// - Password must match the stored password
/// - Rate limiting is handled by the repository layer
/// - Session is established upon successful authentication
class SignInWithEmail implements UseCase<User, SignInWithEmailParams> {
  final AuthRepository repository;

  /// Creates a new [SignInWithEmail] use case.
  /// 
  /// Parameters:
  /// - [repository]: The authentication repository for data operations
  const SignInWithEmail(this.repository);

  /// Execute the email/password sign-in process.
  /// 
  /// This method orchestrates the email authentication flow and handles
  /// all business logic related to email/password authentication.
  /// 
  /// Parameters:
  /// - [params]: Contains email and password for authentication
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [Failure] if sign-in fails
  /// - Right: [User] object if sign-in succeeds
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for invalid email format or empty password
  /// - [AuthFailure.invalidCredentials] for wrong email/password combination
  /// - [AuthFailure.userNotFound] if no account exists with the email
  /// - [AuthFailure.userDisabled] if the account has been disabled
  /// - [AuthFailure.tooManyRequests] for rate limiting
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates input parameters (email format, password presence)
  /// 2. Initiates authentication through repository
  /// 3. Handles authentication result
  /// 4. Updates user's last login timestamp
  /// 5. Provides security logging for failed attempts
  @override
  Future<Either<Failure, User>> call(SignInWithEmailParams params) async {
    try {
      // Step 1: Validate parameters (already done in params creation, but double-check)
      if (params.email.isEmpty || params.password.isEmpty) {
        return Either.left(ValidationFailure('Email and password are required'));
      }

      // Step 2: Attempt authentication through repository
      final result = await repository.signInWithEmail(params.email, params.password);
      
      return result.fold(
        // Handle authentication failure
        (failure) async {
          // Log failed authentication attempt for security monitoring
          await _logFailedSignInAttempt(params.email, failure);
          return Either.left(failure);
        },
        // Handle authentication success
        (user) async {
          // Step 3: Update last login timestamp as part of business logic
          final updatedUser = user.updateLastLogin();
          
          // Step 4: Log successful authentication for security monitoring
          await _logSuccessfulSignIn(user);
          
          // Note: In a more complex implementation, you might:
          // - Check if email verification is required
          // - Update user login statistics
          // - Sync user data with local storage
          // - Track authentication events for analytics
          // - Handle account lockout policies
          
          return Either.right(updatedUser);
        },
      );
    } catch (e) {
      // Handle unexpected errors
      return Either.left(AuthFailure.unknown('Unexpected error during email sign-in: $e'));
    }
  }

  /// Validates email and password combination before attempting sign-in.
  /// 
  /// This method can be used by the presentation layer for early validation
  /// before making the actual authentication request.
  /// 
  /// Parameters:
  /// - [email]: Email address to validate
  /// - [password]: Password to validate
  /// 
  /// Returns [Either<ValidationFailure, bool>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: true if validation passes
  Future<Either<ValidationFailure, bool>> validateCredentials({
    required String email,
    required String password,
  }) async {
    final paramsResult = SignInWithEmailParams.create(
      email: email,
      password: password,
    );

    return paramsResult.fold(
      (failure) => Either.left(failure),
      (_) => Either.right(true),
    );
  }

  /// Checks if an account exists for the given email.
  /// 
  /// This can be used to provide better user experience by showing
  /// appropriate messaging (e.g., "Create account" vs "Sign in").
  /// 
  /// Parameters:
  /// - [email]: Email address to check
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if account exists
  Future<Either<Failure, bool>> checkAccountExists(String email) async {
    // This would typically involve checking with the authentication provider
    // For now, we'll return a placeholder implementation
    // In a real implementation, this might query the repository or auth provider
    
    if (!Email.isValid(email)) {
      return Either.left(ValidationFailure.invalidEmail());
    }
    
    // Placeholder: In a real implementation, this would check account existence
    // without revealing sensitive information (for security)
    return Either.right(true);
  }

  /// Log failed sign-in attempt for security monitoring.
  /// 
  /// This is important for detecting potential security threats
  /// and implementing rate limiting or account protection measures.
  Future<void> _logFailedSignInAttempt(String email, Failure failure) async {
    // In a real implementation, this would:
    // - Log to security monitoring system
    // - Track failed attempt counts
    // - Implement rate limiting
    // - Send security alerts if needed
    
    // For now, this is a placeholder
    // print('Failed sign-in attempt for $email: $failure');
  }

  /// Log successful sign-in for security and analytics.
  /// 
  /// This helps with user behavior analytics and security monitoring.
  Future<void> _logSuccessfulSignIn(User user) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Update user login statistics
    // - Track authentication events
    // - Update security metrics
    
    // For now, this is a placeholder
    // print('Successful sign-in for user: ${user.email}');
  }
}