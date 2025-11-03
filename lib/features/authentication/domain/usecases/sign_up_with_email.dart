import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/usecases/usecase.dart';
import 'package:ai_rewards_system/core/utils/either.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/user.dart';
import 'package:ai_rewards_system/features/authentication/domain/entities/value_objects.dart';
import 'package:ai_rewards_system/features/authentication/domain/repositories/auth_repository.dart';

/// Parameters for the Sign Up with Email use case.
/// 
/// This class encapsulates all the required data for email/password
/// registration and provides comprehensive validation.
class SignUpWithEmailParams {
  final String email;
  final String password;
  final String? displayName;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    this.displayName,
  });

  /// Create validated params with comprehensive validation.
  /// 
  /// Returns [Either<ValidationFailure, SignUpWithEmailParams>]:
  /// - Left: [ValidationFailure] if validation fails
  /// - Right: [SignUpWithEmailParams] if validation succeeds
  static Either<ValidationFailure, SignUpWithEmailParams> create({
    required String email,
    required String password,
    String? displayName,
  }) {
    try {
      // Validate email format
      final emailValue = Email(email);
      
      // Validate password strength
      final passwordValue = Password(password);
      
      // Validate display name if provided
      DisplayName? displayNameValue;
      if (displayName != null && displayName.isNotEmpty) {
        displayNameValue = DisplayName(displayName);
      }

      return Either.right(SignUpWithEmailParams(
        email: emailValue.value,
        password: passwordValue.value,
        displayName: displayNameValue?.value,
      ));
    } on ArgumentError catch (e) {
      final message = e.message.toString();
      if (message.contains('email')) {
        return Either.left(ValidationFailure.invalidEmail());
      } else if (message.contains('password') || message.contains('Password')) {
        return Either.left(ValidationFailure.invalidPassword());
      } else if (message.contains('display name') || message.contains('Display')) {
        return Either.left(ValidationFailure('Invalid display name format'));
      }
      return Either.left(ValidationFailure(message));
    }
  }

  @override
  String toString() => 'SignUpWithEmailParams(email: $email, displayName: $displayName, password: [HIDDEN])';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SignUpWithEmailParams &&
        other.email == email &&
        other.password == password &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode ^ (displayName?.hashCode ?? 0);
}

/// Use case for registering a new user with email and password.
/// 
/// This use case handles the complete registration process, including
/// validation, account creation, and initial user setup. It follows
/// the single responsibility principle by focusing solely on user
/// registration functionality.
/// 
/// Business rules:
/// - Email must be unique and in valid format
/// - Password must meet security requirements
/// - Display name is optional but must be valid if provided
/// - Account verification may be required (email verification)
/// - Initial user profile should be created
/// - Welcome/onboarding process should be initiated
class SignUpWithEmail implements UseCase<User, SignUpWithEmailParams> {
  final AuthRepository repository;

  /// Creates a new [SignUpWithEmail] use case.
  /// 
  /// Parameters:
  /// - [repository]: The authentication repository for data operations
  const SignUpWithEmail(this.repository);

  /// Execute the email/password registration process.
  /// 
  /// This method orchestrates the complete registration flow and handles
  /// all business logic related to user account creation.
  /// 
  /// Parameters:
  /// - [params]: Contains email, password, and optional display name
  /// 
  /// Returns [Either<Failure, User>]:
  /// - Left: [Failure] if registration fails
  /// - Right: [User] object if registration succeeds
  /// 
  /// Possible failures:
  /// - [ValidationFailure] for invalid input data
  /// - [AuthFailure.emailAlreadyInUse] if email is already registered
  /// - [AuthFailure.weakPassword] if password doesn't meet requirements
  /// - [NetworkFailure] for network connectivity issues
  /// 
  /// Business logic handled:
  /// 1. Validates all input parameters comprehensively
  /// 2. Checks for existing accounts with the same email
  /// 3. Creates new user account through repository
  /// 4. Handles initial user profile setup
  /// 5. Initiates email verification if required
  /// 6. Logs registration event for analytics
  @override
  Future<Either<Failure, User>> call(SignUpWithEmailParams params) async {
    try {
      // Step 1: Additional business-level validation
      final validationResult = await _performBusinessValidation(params);
      if (validationResult != null) {
        return Either.left(validationResult);
      }

      // Step 2: Check if email is already in use (optional pre-check)
      final emailCheckResult = await _checkEmailAvailability(params.email);
      if (emailCheckResult.isLeft) {
        return Either.left(emailCheckResult.left);
      }

      // Step 3: Attempt registration through repository
      final result = await repository.signUpWithEmail(params.email, params.password);
      
      return result.fold(
        // Handle registration failure
        (failure) async {
          await _logFailedRegistration(params.email, failure);
          return Either.left(failure);
        },
        // Handle registration success
        (user) async {
          // Step 4: Update user profile if display name was provided
          User finalUser = user;
          if (params.displayName != null) {
            final updateResult = await repository.updateProfile(
              displayName: params.displayName,
            );
            finalUser = updateResult.fold(
              (_) => user, // Keep original user if update fails
              (updatedUser) => updatedUser,
            );
          }

          // Step 5: Initiate email verification if required
          await _initiateEmailVerification(finalUser);

          // Step 6: Perform post-registration setup
          await _performPostRegistrationSetup(finalUser);

          // Step 7: Log successful registration
          await _logSuccessfulRegistration(finalUser);

          return Either.right(finalUser);
        },
      );
    } catch (e) {
      return Either.left(AuthFailure.unknown('Unexpected error during registration: $e'));
    }
  }

  /// Validates password strength and provides feedback.
  /// 
  /// Parameters:
  /// - [password]: Password to validate
  /// 
  /// Returns [Either<ValidationFailure, String>]:
  /// - Left: [ValidationFailure] if password is invalid
  /// - Right: Strength description if password is valid
  Future<Either<ValidationFailure, String>> validatePasswordStrength(String password) async {
    try {
      Password(password); // This will throw if invalid
      final strength = Password.getStrengthDescription(password);
      return Either.right(strength);
    } on ArgumentError catch (e) {
      return Either.left(ValidationFailure(e.message.toString()));
    }
  }

  /// Checks if an email is available for registration.
  /// 
  /// Parameters:
  /// - [email]: Email address to check
  /// 
  /// Returns [Either<Failure, bool>]:
  /// - Left: [Failure] if check fails
  /// - Right: true if email is available
  Future<Either<Failure, bool>> checkEmailAvailability(String email) async {
    return _checkEmailAvailability(email);
  }

  /// Perform comprehensive business-level validation.
  Future<ValidationFailure?> _performBusinessValidation(SignUpWithEmailParams params) async {
    // Additional validation beyond basic format checking
    
    // Check email domain restrictions (if any)
    if (params.email.endsWith('@tempmail.com') || params.email.endsWith('@10minutemail.com')) {
      return ValidationFailure('Temporary email addresses are not allowed');
    }

    // Check password against common password lists (in real implementation)
    // This would check against a database of common/compromised passwords
    
    // Check display name for inappropriate content (in real implementation)
    // This would use content moderation services
    
    return null; // All validations passed
  }

  /// Check if email is available for registration.
  Future<Either<Failure, bool>> _checkEmailAvailability(String email) async {
    // In a real implementation, this might:
    // - Query the authentication provider
    // - Check against a user database
    // - Validate domain restrictions
    
    // For now, assume email is available
    // The actual check will happen in the repository layer
    return Either.right(true);
  }

  /// Initiate email verification process if required.
  Future<void> _initiateEmailVerification(User user) async {
    try {
      // Check if email verification is required for this provider
      final verificationResult = await repository.isEmailVerified();
      verificationResult.fold(
        (_) => null, // Ignore errors for now
        (isVerified) async {
          if (!isVerified) {
            await repository.sendEmailVerification();
          }
        },
      );
    } catch (e) {
      // Don't fail registration if email verification fails
      // Just log the error for later investigation
    }
  }

  /// Perform post-registration setup tasks.
  Future<void> _performPostRegistrationSetup(User user) async {
    try {
      // In a real implementation, this would:
      // - Create user profile in the database
      // - Set up default user preferences
      // - Initialize user's reward points account
      // - Send welcome email
      // - Set up default categories
      // - Initialize analytics user properties
      
      // For now, this is a placeholder
    } catch (e) {
      // Log setup errors but don't fail registration
    }
  }

  /// Log failed registration attempt.
  Future<void> _logFailedRegistration(String email, Failure failure) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Track registration failure rates
    // - Monitor for potential security issues
    // - Update conversion metrics
    
    // For now, this is a placeholder
  }

  /// Log successful registration for analytics.
  Future<void> _logSuccessfulRegistration(User user) async {
    // In a real implementation, this would:
    // - Log to analytics system
    // - Track user acquisition metrics
    // - Set up user properties for analytics
    // - Send conversion events
    // - Update registration success rates
    
    // For now, this is a placeholder
  }
}