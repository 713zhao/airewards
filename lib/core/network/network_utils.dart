import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'network_info.dart';

/// Network utilities for HTTP requests
@lazySingleton
class NetworkUtils {
  final Dio _dio;
  final NetworkInfo _networkInfo;
  
  NetworkUtils(this._networkInfo) : _dio = Dio() {
    _configureDio();
  }

  /// Configure Dio client with interceptors and options
  void _configureDio() {
    _dio.options = BaseOptions(
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint('🌐 HTTP: $object'),
      ));
    }

    // Add network connectivity interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!await _networkInfo.isConnected) {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet connection',
          ));
          return;
        }
        handler.next(options);
      },
    ));

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor());
  }

  /// Make GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  NetworkException _handleDioError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException.timeout();
        
        case DioExceptionType.connectionError:
          return const NetworkException.noConnection();
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode != null) {
            if (statusCode >= 400 && statusCode < 500) {
              return NetworkException.clientError(statusCode, error.message);
            } else if (statusCode >= 500) {
              return NetworkException.serverError(statusCode, error.message);
            }
          }
          return NetworkException.unknown(error.message);
        
        case DioExceptionType.cancel:
          return const NetworkException.cancelled();
        
        case DioExceptionType.badCertificate:
          return const NetworkException.badCertificate();
        
        case DioExceptionType.unknown:
        default:
          return NetworkException.unknown(error.message);
      }
    }
    
    return NetworkException.unknown(error.toString());
  }
}

/// Custom retry interceptor
class RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      debugPrint('🔄 Retrying request (attempt ${retryCount + 1}/$maxRetries)');
      
      // Wait before retrying
      await Future.delayed(retryDelay * (retryCount + 1));
      
      // Update retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      try {
        // Retry the request
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with original error if retry fails
      }
    }

    handler.next(err);
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}