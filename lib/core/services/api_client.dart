import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Comprehensive API client for backend service integration
class ApiClient {
  static const String _baseUrl = 'https://api.airewards.app/v1';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
  static String? _authToken;
  static String? _refreshToken;
  static Timer? _tokenRefreshTimer;
  static Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'AIRewards-Flutter/1.0.0',
  };

  /// Initialize API client with authentication
  static Future<void> initialize({String? token, String? refreshToken}) async {
    debugPrint('🌐 Initializing ApiClient...');
    
    _authToken = token;
    _refreshToken = refreshToken;
    
    if (_authToken != null) {
      _updateAuthHeaders();
      _scheduleTokenRefresh();
    }
    
    debugPrint('✅ ApiClient initialized');
  }

  /// Set authentication token
  static void setAuthToken(String token, {String? refreshToken}) {
    _authToken = token;
    _refreshToken = refreshToken;
    _updateAuthHeaders();
    _scheduleTokenRefresh();
  }

  /// Clear authentication
  static void clearAuth() {
    _authToken = null;
    _refreshToken = null;
    _tokenRefreshTimer?.cancel();
    _defaultHeaders.remove('Authorization');
  }

  /// GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      'GET',
      endpoint,
      queryParams: queryParams,
      headers: headers,
      timeout: timeout,
    );
  }

  /// POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      'POST',
      endpoint,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  /// PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      'PUT',
      endpoint,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  /// DELETE request
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      'DELETE',
      endpoint,
      headers: headers,
      timeout: timeout,
    );
  }

  /// PATCH request
  static Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _makeRequest<T>(
      'PATCH',
      endpoint,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Upload file with progress tracking
  static Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    String fieldName = 'file',
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_defaultHeaders);
      
      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      
      final multipartFile = http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      debugPrint('📤 Uploading file to: ${uri.toString()}');
      
      final streamedResponse = await request.send().timeout(_defaultTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<T>(response);
      
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UPLOAD_FAILED',
          message: e.toString(),
        ),
      );
    }
  }

  /// Make HTTP request with retry logic
  static Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
    int retryCount = 0,
  }) async {
    try {
      // Build URL
      var url = '$_baseUrl/$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url += '?$query';
      }

      final uri = Uri.parse(url);
      
      // Prepare headers
      final requestHeaders = Map<String, String>.from(_defaultHeaders);
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      // Prepare body
      String? requestBody;
      if (body != null) {
        if (body is String) {
          requestBody = body;
        } else {
          requestBody = jsonEncode(body);
        }
      }

      debugPrint('🌐 $method ${uri.toString()}');
      if (kDebugMode && requestBody != null) {
        debugPrint('📤 Request body: $requestBody');
      }

      // Make request
      http.Response response;
      final requestTimeout = timeout ?? _defaultTimeout;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders).timeout(requestTimeout);
          break;
        case 'POST':
          response = await http.post(uri, headers: requestHeaders, body: requestBody).timeout(requestTimeout);
          break;
        case 'PUT':
          response = await http.put(uri, headers: requestHeaders, body: requestBody).timeout(requestTimeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders).timeout(requestTimeout);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: requestHeaders, body: requestBody).timeout(requestTimeout);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      return _handleResponse<T>(response);

    } on TimeoutException {
      debugPrint('⏰ Request timeout for $method $endpoint');
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'TIMEOUT',
          message: 'Request timed out',
        ),
      );
    } on SocketException catch (e) {
      debugPrint('🔌 Network error: $e');
      
      // Retry logic for network errors
      if (retryCount < 3) {
        debugPrint('🔄 Retrying request (attempt ${retryCount + 1})...');
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return _makeRequest<T>(
          method,
          endpoint,
          body: body,
          queryParams: queryParams,
          headers: headers,
          timeout: timeout,
          retryCount: retryCount + 1,
        );
      }
      
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'NETWORK_ERROR',
          message: 'Network connection failed',
          details: e.toString(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Request failed: $e');
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'REQUEST_FAILED',
          message: e.toString(),
        ),
      );
    }
  }

  /// Handle HTTP response
  static ApiResponse<T> _handleResponse<T>(http.Response response) {
    debugPrint('📥 Response: ${response.statusCode}');
    
    if (kDebugMode && response.body.isNotEmpty) {
      debugPrint('📥 Response body: ${response.body}');
    }

    // Handle authentication errors
    if (response.statusCode == 401) {
      _handleUnauthorized();
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'UNAUTHORIZED',
          message: 'Authentication required',
        ),
      );
    }

    // Handle successful responses
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return ApiResponse<T>(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } catch (e) {
        debugPrint('❌ Failed to parse response: $e');
        return ApiResponse<T>(
          success: false,
          error: ApiError(
            code: 'PARSE_ERROR',
            message: 'Failed to parse response',
            details: e.toString(),
          ),
        );
      }
    }

    // Handle error responses
    try {
      final errorData = jsonDecode(response.body);
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: errorData['code'] ?? 'HTTP_ERROR',
          message: errorData['message'] ?? 'Request failed',
          details: errorData['details'],
        ),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: ApiError(
          code: 'HTTP_ERROR',
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  /// Update authentication headers
  static void _updateAuthHeaders() {
    if (_authToken != null) {
      _defaultHeaders['Authorization'] = 'Bearer $_authToken';
    }
  }

  /// Schedule token refresh
  static void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    
    if (_refreshToken != null) {
      // Refresh token every 50 minutes (assuming 1-hour token lifetime)
      _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 50), (_) {
        _refreshAuthToken();
      });
    }
  }

  /// Refresh authentication token
  static Future<void> _refreshAuthToken() async {
    if (_refreshToken == null) return;

    debugPrint('🔄 Refreshing auth token...');

    try {
      final response = await post('auth/refresh', body: {
        'refresh_token': _refreshToken,
      });

      if (response.success && response.data != null) {
        final newToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        setAuthToken(newToken, refreshToken: newRefreshToken);
        debugPrint('✅ Token refreshed successfully');
      } else {
        debugPrint('❌ Token refresh failed');
        _handleUnauthorized();
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
    }
  }

  /// Handle unauthorized responses
  static void _handleUnauthorized() {
    clearAuth();
    // In a real app, navigate to login screen
    debugPrint('🚪 User needs to re-authenticate');
  }

  /// Check network connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Get API health status
  static Future<ApiResponse<Map<String, dynamic>>> getHealthStatus() async {
    return get<Map<String, dynamic>>('health');
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.metadata,
  });

  /// Create successful response
  factory ApiResponse.success(T data, {int? statusCode, Map<String, dynamic>? metadata}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  /// Create error response
  factory ApiResponse.error(ApiError error, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// API Error representation
class ApiError {
  final String code;
  final String message;
  final String? details;
  final Map<String, dynamic>? validationErrors;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
    this.validationErrors,
  });

  @override
  String toString() {
    return 'ApiError(code: $code, message: $message${details != null ? ', details: $details' : ''})';
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const ApiException(this.message, {this.code, this.details});

  @override
  String toString() {
    return 'ApiException: $message${code != null ? ' (code: $code)' : ''}';
  }
}

/// Request interceptor for logging and debugging
class RequestInterceptor {
  static void logRequest(String method, String url, {dynamic body, Map<String, String>? headers}) {
    if (kDebugMode) {
      debugPrint('🌐 API Request: $method $url');
      if (headers != null) {
        debugPrint('📋 Headers: $headers');
      }
      if (body != null) {
        debugPrint('📤 Body: $body');
      }
    }
  }

  static void logResponse(int statusCode, String body) {
    if (kDebugMode) {
      debugPrint('📥 API Response: $statusCode');
      if (body.isNotEmpty) {
        debugPrint('📥 Body: $body');
      }
    }
  }
}