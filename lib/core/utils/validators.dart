import '../utils/either.dart';
import '../errors/failures.dart';

/// Validation utilities for common input validation
class Validators {
  
  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Phone number validation regex (international format)
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );

  /// Password validation (minimum 6 characters, at least one letter and one number)
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$',
  );

  /// Validate email address
  static Either<ValidationFailure, String> validateEmail(String email) {
    if (email.isEmpty) {
      return const Either.left(ValidationFailure('Email is required'));
    }
    
    if (!_emailRegex.hasMatch(email.trim())) {
      return const Either.left(ValidationFailure.invalidEmail());
    }
    
    return Either.right(email.trim());
  }

  /// Validate password
  static Either<ValidationFailure, String> validatePassword(String password) {
    if (password.isEmpty) {
      return const Either.left(ValidationFailure('Password is required'));
    }
    
    if (password.length < 6) {
      return const Either.left(ValidationFailure('Password must be at least 6 characters'));
    }
    
    if (!_passwordRegex.hasMatch(password)) {
      return const Either.left(ValidationFailure('Password must contain at least one letter and one number'));
    }
    
    return Either.right(password);
  }

  /// Validate phone number
  static Either<ValidationFailure, String> validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return const Either.left(ValidationFailure('Phone number is required'));
    }
    
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!_phoneRegex.hasMatch(cleanNumber)) {
      return const Either.left(ValidationFailure.invalidPhoneNumber());
    }
    
    return Either.right(cleanNumber);
  }

  /// Validate required field
  static Either<ValidationFailure, String> validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return Either.left(ValidationFailure.requiredField(fieldName));
    }
    
    return Either.right(value.trim());
  }

  /// Validate minimum length
  static Either<ValidationFailure, String> validateMinLength(
    String value, 
    int minLength, 
    String fieldName,
  ) {
    if (value.length < minLength) {
      return Either.left(ValidationFailure('$fieldName must be at least $minLength characters'));
    }
    
    return Either.right(value);
  }

  /// Validate maximum length
  static Either<ValidationFailure, String> validateMaxLength(
    String value, 
    int maxLength, 
    String fieldName,
  ) {
    if (value.length > maxLength) {
      return Either.left(ValidationFailure('$fieldName must be at most $maxLength characters'));
    }
    
    return Either.right(value);
  }

  /// Validate numeric input
  static Either<ValidationFailure, int> validateInteger(String value, String fieldName) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return Either.left(ValidationFailure('$fieldName must be a valid number'));
    }
    
    return Either.right(parsed);
  }

  /// Validate double input
  static Either<ValidationFailure, double> validateDouble(String value, String fieldName) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return Either.left(ValidationFailure('$fieldName must be a valid decimal number'));
    }
    
    return Either.right(parsed);
  }

  /// Validate range for numbers
  static Either<ValidationFailure, T> validateRange<T extends num>(
    T value, 
    T min, 
    T max, 
    String fieldName,
  ) {
    if (value < min || value > max) {
      return Either.left(ValidationFailure('$fieldName must be between $min and $max'));
    }
    
    return Either.right(value);
  }

  /// Validate URL
  static Either<ValidationFailure, String> validateUrl(String url) {
    if (url.isEmpty) {
      return const Either.left(ValidationFailure('URL is required'));
    }
    
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return const Either.left(ValidationFailure('URL must start with http:// or https://'));
      }
      return Either.right(url);
    } catch (e) {
      return const Either.left(ValidationFailure('Invalid URL format'));
    }
  }

  /// Validate confirmation field (e.g., confirm password)
  static Either<ValidationFailure, String> validateConfirmation(
    String value, 
    String originalValue, 
    String fieldName,
  ) {
    if (value != originalValue) {
      return Either.left(ValidationFailure('$fieldName does not match'));
    }
    
    return Either.right(value);
  }

  /// Chain multiple validations for a single field
  static Either<ValidationFailure, String> chain(
    String value,
    List<Either<ValidationFailure, String> Function(String)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result.isLeft) {
        return result;
      }
      value = result.right; // Use the transformed value for next validation
    }
    return Either.right(value);
  }

  /// Validate multiple fields at once
  static Either<ValidationFailure, Map<String, dynamic>> validateForm(
    Map<String, dynamic> formData,
    Map<String, List<Either<ValidationFailure, dynamic> Function(dynamic)>> fieldValidators,
  ) {
    final validatedData = <String, dynamic>{};
    final errors = <String, String>{};
    
    for (final entry in fieldValidators.entries) {
      final fieldName = entry.key;
      final validators = entry.value;
      final fieldValue = formData[fieldName];
      
      // Run all validators for this field
      dynamic validatedValue = fieldValue;
      for (final validator in validators) {
        final result = validator(validatedValue);
        if (result.isLeft) {
          errors[fieldName] = result.left.message;
          break; // Stop at first error for this field
        }
        validatedValue = result.right;
      }
      
      if (!errors.containsKey(fieldName)) {
        validatedData[fieldName] = validatedValue;
      }
    }
    
    if (errors.isEmpty) {
      return Either.right(validatedData);
    } else {
      return Either.left(ValidationFailure.multipleErrors(errors));
    }
  }

  // Simple form validators that return String? for Flutter form validation

  /// Simple email validator for forms
  static String? validateEmailForm(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Simple password validator for forms
  static String? validatePasswordForm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (!_passwordRegex.hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }
    
    return null;
  }

  /// Simple required field validator for forms
  static String? validateRequiredForm(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  /// Simple name validator for forms
  static String? validateNameForm(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return '$fieldName must not exceed 50 characters';
    }
    
    return null;
  }

  /// Simple confirm password validator for forms
  static String? validateConfirmPasswordForm(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}