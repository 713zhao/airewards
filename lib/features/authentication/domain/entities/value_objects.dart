import 'package:equatable/equatable.dart';

/// Value object representing an email address with validation
class Email extends Equatable {
  final String value;

  const Email._(this.value);

  /// Factory constructor that validates the email format
  factory Email(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    if (!_isValidEmail(trimmedEmail)) {
      throw ArgumentError('Invalid email format: $email');
    }
    return Email._(trimmedEmail);
  }

  /// Validates email format using regex
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Returns true if the email string is valid
  static bool isValid(String email) {
    try {
      Email(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns the domain part of the email
  String get domain {
    final atIndex = value.indexOf('@');
    return atIndex != -1 ? value.substring(atIndex + 1) : '';
  }

  /// Returns the local part (before @) of the email
  String get localPart {
    final atIndex = value.indexOf('@');
    return atIndex != -1 ? value.substring(0, atIndex) : value;
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

/// Value object representing a password with validation rules
class Password extends Equatable {
  final String value;

  const Password._(this.value);

  /// Factory constructor that validates password strength
  factory Password(String password) {
    if (!_isValidPassword(password)) {
      throw ArgumentError('Password does not meet security requirements');
    }
    return Password._(password);
  }

  /// Validates password strength
  static bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (password.length > 128) return false;
    
    // Must contain at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Must contain at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Must contain at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    return true;
  }

  /// Returns true if the password string meets requirements
  static bool isValid(String password) {
    return _isValidPassword(password);
  }

  /// Returns password strength score (0-4)
  static int getStrengthScore(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    return score;
  }

  /// Returns password strength description
  static String getStrengthDescription(String password) {
    final score = getStrengthScore(password);
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Length of the password
  int get length => value.length;

  @override
  List<Object> get props => [value];

  @override
  String toString() => '*' * value.length; // Hide actual password
}

/// Value object representing a user's display name
class DisplayName extends Equatable {
  final String value;

  const DisplayName._(this.value);

  /// Factory constructor that validates display name
  factory DisplayName(String name) {
    final trimmedName = name.trim();
    if (!_isValidDisplayName(trimmedName)) {
      throw ArgumentError('Invalid display name: $name');
    }
    return DisplayName._(trimmedName);
  }

  /// Validates display name format
  static bool _isValidDisplayName(String name) {
    if (name.isEmpty) return false;
    if (name.length > 50) return false;
    
    // Must contain at least one non-whitespace character
    if (name.trim().isEmpty) return false;
    
    // Should not contain only special characters
    final alphanumeric = RegExp(r'[a-zA-Z0-9]');
    if (!alphanumeric.hasMatch(name)) return false;
    
    return true;
  }

  /// Returns true if the display name string is valid
  static bool isValid(String name) {
    return _isValidDisplayName(name.trim());
  }

  /// Returns the first word of the display name
  String get firstName {
    final words = value.split(' ');
    return words.isNotEmpty ? words.first : value;
  }

  /// Returns the last word of the display name
  String get lastName {
    final words = value.split(' ');
    return words.length > 1 ? words.last : '';
  }

  /// Returns initials from the display name
  String get initials {
    final words = value.split(' ').where((word) => word.isNotEmpty);
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return words.take(2).map((word) => word.substring(0, 1).toUpperCase()).join();
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}