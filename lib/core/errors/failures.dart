import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(String message, [int? code]) : super(message, code);

  const NetworkFailure.timeout() : super('Connection timeout');
  const NetworkFailure.noConnection() : super('No internet connection');
  const NetworkFailure.cancelled() : super('Request cancelled');
  const NetworkFailure.badCertificate() : super('Invalid SSL certificate');
  const NetworkFailure.clientError(int code, String message) : super(message, code);
  const NetworkFailure.serverError(int code, String message) : super(message, code);
  const NetworkFailure.unknown([String? message]) : super(message ?? 'Unknown network error');
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(String message, [int? code]) : super(message, code);

  const AuthFailure.invalidCredentials() : super('Invalid email or password');
  const AuthFailure.userNotFound() : super('User account not found');
  const AuthFailure.emailAlreadyInUse() : super('Email is already registered');
  const AuthFailure.weakPassword() : super('Password is too weak');
  const AuthFailure.userDisabled() : super('User account is disabled');
  const AuthFailure.tooManyRequests() : super('Too many requests. Try again later');
  const AuthFailure.sessionExpired() : super('Session has expired');
  const AuthFailure.requiresRecentLogin() : super('Please sign in again');
  const AuthFailure.invalidVerificationCode() : super('Invalid verification code');
  const AuthFailure.invalidPhoneNumber() : super('Invalid phone number');
  const AuthFailure.cancelled() : super('Authentication cancelled');
  const AuthFailure.invalidOperation() : super('Invalid authentication operation');
  const AuthFailure.unknown([String? message]) : super(message ?? 'Authentication error');
}

/// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(String message, [int? code]) : super(message, code);

  const DatabaseFailure.notFound() : super('Data not found');
  const DatabaseFailure.insertFailed() : super('Failed to save data');
  const DatabaseFailure.updateFailed() : super('Failed to update data');
  const DatabaseFailure.deleteFailed() : super('Failed to delete data');
  const DatabaseFailure.connectionFailed() : super('Database connection failed');
  const DatabaseFailure.permissionDenied() : super('Database permission denied');
  const DatabaseFailure.unknown([String? message]) : super(message ?? 'Database error');
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(String message, [int? code]) : super(message, code);

  const CacheFailure.notFound() : super('Cache data not found');
  const CacheFailure.expired() : super('Cache data expired');
  const CacheFailure.writeFailed() : super('Failed to write cache');
  const CacheFailure.readFailed() : super('Failed to read cache');
  const CacheFailure.unknown([String? message]) : super(message ?? 'Cache error');
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(String message, [this.fieldErrors]) : super(message);

  const ValidationFailure.invalidEmail() : fieldErrors = null, super('Invalid email address');
  const ValidationFailure.invalidPassword() : fieldErrors = null, super('Invalid password');
  const ValidationFailure.invalidPhoneNumber() : fieldErrors = null, super('Invalid phone number');
  const ValidationFailure.requiredField(String field) : fieldErrors = null, super('$field is required');
  const ValidationFailure.multipleErrors(Map<String, String> errors) : fieldErrors = errors, super('Multiple validation errors');

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(String message, [int? code]) : super(message, code);

  const PermissionFailure.denied() : super('Permission denied');
  const PermissionFailure.restricted() : super('Permission restricted');
  const PermissionFailure.notRequested() : super('Permission not requested');
  const PermissionFailure.unknown([String? message]) : super(message ?? 'Permission error');
}

/// Business logic failures
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure(String message, [int? code]) : super(message, code);

  const BusinessLogicFailure.insufficientPoints() : super('Insufficient reward points');
  const BusinessLogicFailure.itemUnavailable() : super('Item is not available');
  const BusinessLogicFailure.invalidOperation() : super('Invalid operation');
  const BusinessLogicFailure.limitExceeded() : super('Operation limit exceeded');
  const BusinessLogicFailure.unknown([String? message]) : super(message ?? 'Business logic error');
}

/// Generic failure for unknown errors
class GenericFailure extends Failure {
  const GenericFailure(String message, [int? code]) : super(message, code);
}