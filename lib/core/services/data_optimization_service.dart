import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

/// Data optimization service for efficient loading and caching
@lazySingleton
class DataOptimizationService {
  static const String _cacheBoxName = 'data_cache';
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  static const int _maxCacheSize = 50; // Maximum cached items
  
  static Box<String>? _cacheBox;
  static final Map<String, Timer> _cacheTimers = {};
  static final Map<String, Completer<dynamic>> _ongoingRequests = {};
  
  /// Initialize data optimization service
  static Future<void> initialize() async {
    try {
      // Open cache box
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      
      // Clean expired cache entries
      await _cleanExpiredCache();
      
      debugPrint('💾 DataOptimizationService initialized');
    } catch (e) {
      debugPrint('⚠️ DataOptimizationService initialization failed: $e');
    }
  }

  /// Clean expired cache entries
  static Future<void> _cleanExpiredCache() async {
    if (_cacheBox == null) return;
    
    try {
      final keysToDelete = <String>[];
      
      for (final key in _cacheBox!.keys) {
        if (key.endsWith('_timestamp')) {
          final timestampStr = _cacheBox!.get(key);
          if (timestampStr != null) {
            final timestamp = DateTime.tryParse(timestampStr);
            if (timestamp != null) {
              final age = DateTime.now().difference(timestamp);
              if (age > _defaultCacheDuration) {
                final dataKey = key.replaceAll('_timestamp', '');
                keysToDelete.addAll([key, dataKey]);
              }
            }
          }
        }
      }
      
      for (final key in keysToDelete) {
        await _cacheBox!.delete(key);
      }
      
      if (keysToDelete.isNotEmpty) {
        debugPrint('🧹 Cleaned ${keysToDelete.length ~/ 2} expired cache entries');
      }
    } catch (e) {
      debugPrint('⚠️ Cache cleaning failed: $e');
    }
  }

  /// Cache data with expiration
  static Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? cacheDuration,
  }) async {
    if (_cacheBox == null) return;
    
    try {
      final duration = cacheDuration ?? _defaultCacheDuration;
      final jsonData = jsonEncode(data);
      final timestamp = DateTime.now().add(duration).toIso8601String();
      
      await _cacheBox!.put(key, jsonData);
      await _cacheBox!.put('${key}_timestamp', timestamp);
      
      // Set up auto-expiration timer
      _cacheTimers[key]?.cancel();
      _cacheTimers[key] = Timer(duration, () async {
        await _cacheBox!.delete(key);
        await _cacheBox!.delete('${key}_timestamp');
        _cacheTimers.remove(key);
      });
      
      // Maintain cache size limit
      await _maintainCacheSize();
      
    } catch (e) {
      debugPrint('⚠️ Failed to cache data for key $key: $e');
    }
  }

  /// Get cached data
  static Future<T?> getCachedData<T>(String key) async {
    if (_cacheBox == null) return null;
    
    try {
      // Check if data exists and is not expired
      final timestampStr = _cacheBox!.get('${key}_timestamp');
      if (timestampStr != null) {
        final expirationTime = DateTime.tryParse(timestampStr);
        if (expirationTime != null && DateTime.now().isAfter(expirationTime)) {
          // Data expired, remove it
          await _cacheBox!.delete(key);
          await _cacheBox!.delete('${key}_timestamp');
          return null;
        }
      }
      
      final jsonData = _cacheBox!.get(key);
      if (jsonData != null) {
        final data = jsonDecode(jsonData);
        return data as T?;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get cached data for key $key: $e');
    }
    
    return null;
  }

  /// Maintain cache size within limits
  static Future<void> _maintainCacheSize() async {
    if (_cacheBox == null) return;
    
    try {
      final dataKeys = _cacheBox!.keys
          .where((key) => !key.toString().endsWith('_timestamp'))
          .toList();
      
      if (dataKeys.length > _maxCacheSize) {
        // Remove oldest entries
        final keysToRemove = dataKeys.take(dataKeys.length - _maxCacheSize);
        
        for (final key in keysToRemove) {
          await _cacheBox!.delete(key);
          await _cacheBox!.delete('${key}_timestamp');
          _cacheTimers[key]?.cancel();
          _cacheTimers.remove(key);
        }
        
        debugPrint('🗑️ Removed ${keysToRemove.length} old cache entries');
      }
    } catch (e) {
      debugPrint('⚠️ Cache size maintenance failed: $e');
    }
  }

  /// Optimized data fetch with caching and deduplication
  static Future<T> fetchData<T>({
    required String cacheKey,
    required Future<T> Function() dataFetcher,
    Duration? cacheDuration,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cachedData = await getCachedData<T>(cacheKey);
      if (cachedData != null) {
        debugPrint('📥 Cache hit for key: $cacheKey');
        return cachedData;
      }
    }
    
    // Deduplicate ongoing requests
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('🔄 Deduplicating request for key: $cacheKey');
      return await _ongoingRequests[cacheKey]!.future as T;
    }
    
    // Create new request
    final completer = Completer<dynamic>();
    _ongoingRequests[cacheKey] = completer;
    
    try {
      debugPrint('🌐 Fetching fresh data for key: $cacheKey');
      final data = await dataFetcher();
      
      // Cache the result
      if (useCache) {
        await cacheData(cacheKey, data, cacheDuration: cacheDuration);
      }
      
      completer.complete(data);
      return data;
      
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      _ongoingRequests.remove(cacheKey);
    }
  }

  /// Batch data fetching to reduce number of requests
  static Future<Map<String, T>> batchFetchData<T>({
    required Map<String, Future<T> Function()> requests,
    Duration? cacheDuration,
    bool useCache = true,
  }) async {
    final results = <String, T>{};
    final pendingRequests = <String, Future<T> Function()>{};
    
    // Check cache for all requests first
    if (useCache) {
      for (final entry in requests.entries) {
        final cachedData = await getCachedData<T>(entry.key);
        if (cachedData != null) {
          results[entry.key] = cachedData;
          debugPrint('📥 Batch cache hit for key: ${entry.key}');
        } else {
          pendingRequests[entry.key] = entry.value;
        }
      }
    } else {
      pendingRequests.addAll(requests);
    }
    
    // Fetch remaining data concurrently
    if (pendingRequests.isNotEmpty) {
      debugPrint('🌐 Batch fetching ${pendingRequests.length} items');
      
      final futures = pendingRequests.map(
        (key, fetcher) => MapEntry(key, fetchData<T>(
          cacheKey: key,
          dataFetcher: fetcher,
          cacheDuration: cacheDuration,
          useCache: useCache,
        )),
      );
      
      final freshResults = await Future.wait(futures.values);
      
      int index = 0;
      for (final key in futures.keys) {
        results[key] = freshResults[index];
        index++;
      }
    }
    
    return results;
  }

  /// Preload data for improved user experience
  static Future<void> preloadData({
    required String cacheKey,
    required Future<dynamic> Function() dataFetcher,
    Duration? cacheDuration,
  }) async {
    try {
      // Check if data is already cached and fresh
      final cachedData = await getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('📋 Data already preloaded for key: $cacheKey');
        return;
      }
      
      // Preload in background
      debugPrint('⚡ Preloading data for key: $cacheKey');
      
      final data = await dataFetcher();
      await cacheData(cacheKey, data, cacheDuration: cacheDuration);
      
      debugPrint('✅ Successfully preloaded data for key: $cacheKey');
      
    } catch (e) {
      debugPrint('⚠️ Failed to preload data for key $cacheKey: $e');
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    if (_cacheBox == null) return;
    
    try {
      await _cacheBox!.clear();
      
      // Cancel all timers
      for (final timer in _cacheTimers.values) {
        timer.cancel();
      }
      _cacheTimers.clear();
      
      debugPrint('🧹 All cached data cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear cache: $e');
    }
  }

  /// Clear cache for specific key pattern
  static Future<void> clearCachePattern(String pattern) async {
    if (_cacheBox == null) return;
    
    try {
      final keysToDelete = <String>[];
      
      for (final key in _cacheBox!.keys) {
        if (key.toString().contains(pattern)) {
          keysToDelete.add(key.toString());
        }
      }
      
      for (final key in keysToDelete) {
        await _cacheBox!.delete(key);
        _cacheTimers[key]?.cancel();
        _cacheTimers.remove(key);
      }
      
      debugPrint('🧹 Cleared ${keysToDelete.length} cache entries matching pattern: $pattern');
    } catch (e) {
      debugPrint('⚠️ Failed to clear cache pattern $pattern: $e');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    if (_cacheBox == null) return {};
    
    try {
      final allKeys = _cacheBox!.keys.toList();
      final dataKeys = allKeys.where((key) => !key.toString().endsWith('_timestamp')).length;
      final totalSize = _cacheBox!.length;
      
      return {
        'total_entries': dataKeys,
        'total_keys': totalSize,
        'max_size': _maxCacheSize,
        'active_timers': _cacheTimers.length,
        'ongoing_requests': _ongoingRequests.length,
        'cache_hit_rate': _calculateCacheHitRate(),
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get cache stats: $e');
      return {};
    }
  }

  /// Calculate approximate cache hit rate
  static double _calculateCacheHitRate() {
    // This is a simplified calculation
    // In production, you'd want to track hits/misses more precisely
    final cacheSize = _cacheBox?.length ?? 0;
    final ongoingRequests = _ongoingRequests.length;
    
    if (cacheSize + ongoingRequests == 0) return 0.0;
    
    return cacheSize / (cacheSize + ongoingRequests);
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    // Cancel all timers
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();
    
    // Complete any ongoing requests with errors
    for (final completer in _ongoingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Service disposed');
      }
    }
    _ongoingRequests.clear();
    
    // Close cache box
    await _cacheBox?.close();
    _cacheBox = null;
    
    debugPrint('🧹 DataOptimizationService disposed');
  }
}

/// Paginated data loader for efficient large dataset handling
class PaginatedDataLoader<T> {
  final Future<List<T>> Function(int page, int pageSize) _dataFetcher;
  final int _pageSize;
  
  final List<T> _allData = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  
  PaginatedDataLoader({
    required Future<List<T>> Function(int page, int pageSize) dataFetcher,
    int pageSize = 20,
  })  : _dataFetcher = dataFetcher,
        _pageSize = pageSize;

  /// Get currently loaded data
  List<T> get data => List.unmodifiable(_allData);
  
  /// Check if more data is available
  bool get hasMore => _hasMore;
  
  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Load next page of data
  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    
    try {
      final cacheKey = 'paginated_data_page_$_currentPage';
      
      final pageData = await DataOptimizationService.fetchData<List<T>>(
        cacheKey: cacheKey,
        dataFetcher: () => _dataFetcher(_currentPage, _pageSize),
        cacheDuration: const Duration(minutes: 30),
      );
      
      if (pageData.length < _pageSize) {
        _hasMore = false;
      }
      
      _allData.addAll(pageData);
      _currentPage++;
      
    } catch (e) {
      debugPrint('⚠️ Failed to load page $_currentPage: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Reset loader to initial state
  void reset() {
    _allData.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
  }
}