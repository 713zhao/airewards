/// Base exception class for the application
abstract class AppException implements Exception {
  const AppException();
}

/// Network-related exceptions
class NetworkException extends AppException {
  final String message;
  final int? statusCode;

  const NetworkException(this.message, [this.statusCode]);

  const NetworkException.timeout() 
      : message = 'Request timeout', statusCode = null;

  const NetworkException.noConnection() 
      : message = 'No internet connection', statusCode = null;

  const NetworkException.cancelled() 
      : message = 'Request was cancelled', statusCode = null;

  const NetworkException.badCertificate() 
      : message = 'Invalid SSL certificate', statusCode = null;

  const NetworkException.clientError(int code, String? msg)
      : message = msg ?? 'Client error occurred', statusCode = code;

  const NetworkException.serverError(int code, String? msg)
      : message = msg ?? 'Server error occurred', statusCode = code;

  const NetworkException.unknown([String? msg])
      : message = msg ?? 'Unknown network error', statusCode = null;

  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Code: $statusCode)' : ''}';
}

/// Database-related exceptions
class DatabaseException extends AppException {
  final String message;

  const DatabaseException(this.message);

  const DatabaseException.notFound() : message = 'Data not found';
  const DatabaseException.insertFailed() : message = 'Failed to insert data';
  const DatabaseException.updateFailed() : message = 'Failed to update data';
  const DatabaseException.deleteFailed() : message = 'Failed to delete data';
  const DatabaseException.connectionFailed() : message = 'Database connection failed';

  @override
  String toString() => 'DatabaseException: $message';
}

/// Cache-related exceptions
class CacheException extends AppException {
  final String message;

  const CacheException(this.message);

  const CacheException.notFound() : message = 'Cache data not found';
  const CacheException.expired() : message = 'Cache data expired';
  const CacheException.writeFailed() : message = 'Failed to write cache';
  const CacheException.readFailed() : message = 'Failed to read cache';

  @override
  String toString() => 'CacheException: $message';
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException(this.message, [this.fieldErrors]);

  @override
  String toString() => 'ValidationException: $message';
}

/// Permission-related exceptions  
class PermissionException extends AppException {
  final String message;

  const PermissionException(this.message);

  const PermissionException.denied() : message = 'Permission denied';
  const PermissionException.restricted() : message = 'Permission restricted';
  const PermissionException.notRequested() : message = 'Permission not requested';

  @override
  String toString() => 'PermissionException: $message';
}

/// Local storage-related exceptions
class LocalException extends AppException {
  final String message;

  const LocalException(this.message);

  const LocalException.notFound() : message = 'Local data not found';
  const LocalException.storageFailed() : message = 'Failed to store data locally';
  const LocalException.retrievalFailed() : message = 'Failed to retrieve local data';
  const LocalException.cacheMiss() : message = 'Cache miss - data not available';

  @override
  String toString() => 'LocalException: $message';
}

/// Authentication-related exceptions
class AuthException extends AppException {
  final String message;

  const AuthException(this.message);

  const AuthException.unauthenticated() : message = 'User is not authenticated';
  const AuthException.unauthorized() : message = 'User is not authorized';
  const AuthException.tokenExpired() : message = 'Authentication token has expired';
  const AuthException.invalidCredentials() : message = 'Invalid login credentials';
  const AuthException.accountDisabled() : message = 'Account has been disabled';
  const AuthException.networkError() : message = 'Network error during authentication';

  @override
  String toString() => 'AuthException: $message';
}