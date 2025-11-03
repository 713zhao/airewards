import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../errors/exceptions.dart';
import '../errors/failures.dart';
import 'either.dart';

/// Utility class for error handling and conversion
class ErrorHandler {
  
  /// Convert Exception to Failure
  static Failure handleException(Exception exception) {
    if (exception is NetworkException) {
      return _handleNetworkException(exception);
    } else if (exception is DatabaseException) {
      return _handleDatabaseException(exception);
    } else if (exception is CacheException) {
      return _handleCacheException(exception);
    } else if (exception is ValidationException) {
      return _handleValidationException(exception);
    } else if (exception is PermissionException) {
      return _handlePermissionException(exception);
    } else if (exception is FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    } else if (exception is FirebaseException) {
      return _handleFirebaseException(exception);
    } else if (exception is DioException) {
      return _handleDioException(exception);
    } else {
      return GenericFailure('Unexpected error: ${exception.toString()}');
    }
  }

  /// Handle NetworkException
  static NetworkFailure _handleNetworkException(NetworkException exception) {
    switch (exception.runtimeType) {
      case const (NetworkException):
        if (exception.message.contains('timeout')) {
          return const NetworkFailure.timeout();
        } else if (exception.message.contains('connection')) {
          return const NetworkFailure.noConnection();
        } else if (exception.message.contains('cancelled')) {
          return const NetworkFailure.cancelled();
        } else if (exception.message.contains('certificate')) {
          return const NetworkFailure.badCertificate();
        } else if (exception.statusCode != null) {
          final code = exception.statusCode!;
          if (code >= 400 && code < 500) {
            return NetworkFailure.clientError(code, exception.message);
          } else if (code >= 500) {
            return NetworkFailure.serverError(code, exception.message);
          }
        }
        return NetworkFailure.unknown(exception.message);
      default:
        return NetworkFailure.unknown(exception.message);
    }
  }

  /// Handle DatabaseException
  static DatabaseFailure _handleDatabaseException(DatabaseException exception) {
    if (exception.message.contains('not found')) {
      return const DatabaseFailure.notFound();
    } else if (exception.message.contains('insert')) {
      return const DatabaseFailure.insertFailed();
    } else if (exception.message.contains('update')) {
      return const DatabaseFailure.updateFailed();
    } else if (exception.message.contains('delete')) {
      return const DatabaseFailure.deleteFailed();
    } else if (exception.message.contains('connection')) {
      return const DatabaseFailure.connectionFailed();
    } else if (exception.message.contains('permission')) {
      return const DatabaseFailure.permissionDenied();
    } else {
      return DatabaseFailure.unknown(exception.message);
    }
  }

  /// Handle CacheException
  static CacheFailure _handleCacheException(CacheException exception) {
    if (exception.message.contains('not found')) {
      return const CacheFailure.notFound();
    } else if (exception.message.contains('expired')) {
      return const CacheFailure.expired();
    } else if (exception.message.contains('write')) {
      return const CacheFailure.writeFailed();
    } else if (exception.message.contains('read')) {
      return const CacheFailure.readFailed();
    } else {
      return CacheFailure.unknown(exception.message);
    }
  }

  /// Handle ValidationException
  static ValidationFailure _handleValidationException(ValidationException exception) {
    if (exception.fieldErrors != null) {
      return ValidationFailure.multipleErrors(exception.fieldErrors!);
    } else if (exception.message.contains('email')) {
      return const ValidationFailure.invalidEmail();
    } else if (exception.message.contains('password')) {
      return const ValidationFailure.invalidPassword();
    } else if (exception.message.contains('phone')) {
      return const ValidationFailure.invalidPhoneNumber();
    } else {
      return ValidationFailure(exception.message);
    }
  }

  /// Handle PermissionException
  static PermissionFailure _handlePermissionException(PermissionException exception) {
    if (exception.message.contains('denied')) {
      return const PermissionFailure.denied();
    } else if (exception.message.contains('restricted')) {
      return const PermissionFailure.restricted();
    } else if (exception.message.contains('not requested')) {
      return const PermissionFailure.notRequested();
    } else {
      return PermissionFailure.unknown(exception.message);
    }
  }

  /// Handle FirebaseAuthException
  static AuthFailure _handleFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return const AuthFailure.invalidCredentials();
      case 'email-already-in-use':
        return const AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return const AuthFailure.weakPassword();
      case 'user-disabled':
        return const AuthFailure.userDisabled();
      case 'too-many-requests':
        return const AuthFailure.tooManyRequests();
      case 'requires-recent-login':
        return const AuthFailure.requiresRecentLogin();
      case 'invalid-verification-code':
        return const AuthFailure.invalidVerificationCode();
      case 'invalid-phone-number':
        return const AuthFailure.invalidPhoneNumber();
      case 'session-expired':
        return const AuthFailure.sessionExpired();
      default:
        return AuthFailure.unknown(exception.message);
    }
  }

  /// Handle FirebaseException (Firestore, etc.)
  static DatabaseFailure _handleFirebaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return const DatabaseFailure.permissionDenied();
      case 'not-found':
        return const DatabaseFailure.notFound();
      case 'already-exists':
        return const DatabaseFailure.insertFailed();
      case 'failed-precondition':
        return const DatabaseFailure.updateFailed();
      case 'unavailable':
        return const DatabaseFailure.connectionFailed();
      default:
        return DatabaseFailure.unknown(exception.message);
    }
  }

  /// Handle DioException
  static NetworkFailure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure.timeout();
      case DioExceptionType.connectionError:
        return const NetworkFailure.noConnection();
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        if (statusCode != null) {
          if (statusCode >= 400 && statusCode < 500) {
            return NetworkFailure.clientError(statusCode, exception.message ?? 'Client error');
          } else if (statusCode >= 500) {
            return NetworkFailure.serverError(statusCode, exception.message ?? 'Server error');
          }
        }
        return NetworkFailure.unknown(exception.message);
      case DioExceptionType.cancel:
        return const NetworkFailure.cancelled();
      case DioExceptionType.badCertificate:
        return const NetworkFailure.badCertificate();
      case DioExceptionType.unknown:
        return NetworkFailure.unknown(exception.message);
    }
  }

  /// Execute a function and return Either<Failure, T>
  static Future<Either<Failure, T>> execute<T>(Future<T> Function() function) async {
    try {
      final result = await function();
      return Either.right(result);
    } on Exception catch (exception) {
      final failure = handleException(exception);
      return Either.left(failure);
    } catch (error) {
      final failure = GenericFailure('Unexpected error: $error');
      return Either.left(failure);
    }
  }

  /// Execute a synchronous function and return Either<Failure, T>
  static Either<Failure, T> executeSync<T>(T Function() function) {
    try {
      final result = function();
      return Either.right(result);
    } on Exception catch (exception) {
      final failure = handleException(exception);
      return Either.left(failure);
    } catch (error) {
      final failure = GenericFailure('Unexpected error: $error');
      return Either.left(failure);
    }
  }

  /// Convert a nullable value to Either with custom failure
  static Either<Failure, T> fromNullable<T>(T? value, Failure failure) {
    if (value != null) {
      return Either.right(value);
    }
    return Either.left(failure);
  }

  /// Validate input and return Either
  static Either<ValidationFailure, T> validate<T>(
    T value,
    bool Function(T) validator,
    String errorMessage,
  ) {
    if (validator(value)) {
      return Either.right(value);
    }
    return Either.left(ValidationFailure(errorMessage));
  }

  /// Chain multiple validations
  static Either<ValidationFailure, Map<String, dynamic>> validateAll(
    Map<String, dynamic> data,
    Map<String, bool Function(dynamic)> validators,
  ) {
    final errors = <String, String>{};
    
    for (final entry in validators.entries) {
      final field = entry.key;
      final validator = entry.value;
      final value = data[field];
      
      if (!validator(value)) {
        errors[field] = 'Invalid $field';
      }
    }
    
    if (errors.isEmpty) {
      return Either.right(data);
    } else {
      return Either.left(ValidationFailure.multipleErrors(errors));
    }
  }
}