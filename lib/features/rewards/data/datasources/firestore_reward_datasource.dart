import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../models/models.dart';

/// Remote data source for Firestore reward operations.
/// 
/// This class handles all Firestore operations for reward entries including
/// batch operations for point transactions, real-time listeners for data
/// synchronization, and proper document/collection structure management.
/// 
/// Key features:
/// - Real-time reward data synchronization with listeners
/// - Batch operations for atomic point transactions
/// - Category-based filtering and pagination
/// - Comprehensive error handling and recovery
/// - Proper document structure and indexing
/// - User-specific reward collections
abstract class FirestoreRewardDataSource {
  /// Stream of user's reward entries with real-time updates
  /// 
  /// Parameters:
  /// - [userId]: User ID to get rewards for
  /// - [categoryId]: Optional category filter
  /// - [limit]: Number of entries to fetch (default 50)
  /// 
  /// Returns [Stream<List<RewardEntryModel>>] with real-time updates
  Stream<List<RewardEntryModel>> getRewardEntriesStream({
    required String userId,
    String? categoryId,
    int limit = 50,
  });
  
  /// Get paginated reward entries
  /// 
  /// Parameters:
  /// - [userId]: User ID to get rewards for
  /// - [categoryId]: Optional category filter
  /// - [startAfter]: Document to start after for pagination
  /// - [limit]: Number of entries to fetch
  /// 
  /// Returns [Either<NetworkException, List<RewardEntryModel>>]
  Future<Either<NetworkException, List<RewardEntryModel>>> getRewardEntries({
    required String userId,
    String? categoryId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  });
  
  /// Add new reward entry
  /// 
  /// Parameters:
  /// - [rewardEntry]: Reward entry to add
  /// 
  /// Returns [Either<NetworkException, RewardEntryModel>] with generated ID
  Future<Either<NetworkException, RewardEntryModel>> addRewardEntry(
    RewardEntryModel rewardEntry,
  );
  
  /// Update existing reward entry
  /// 
  /// Parameters:
  /// - [rewardEntry]: Updated reward entry
  /// 
  /// Returns [Either<NetworkException, RewardEntryModel>]
  Future<Either<NetworkException, RewardEntryModel>> updateRewardEntry(
    RewardEntryModel rewardEntry,
  );
  
  /// Delete reward entry
  /// 
  /// Parameters:
  /// - [entryId]: ID of entry to delete
  /// 
  /// Returns [Either<NetworkException, void>]
  Future<Either<NetworkException, void>> deleteRewardEntry(String entryId);
  
  /// Batch update multiple reward entries atomically
  /// 
  /// Parameters:
  /// - [entries]: List of entries to update
  /// 
  /// Returns [Either<NetworkException, List<RewardEntryModel>>]
  Future<Either<NetworkException, List<RewardEntryModel>>> batchUpdateEntries(
    List<RewardEntryModel> entries,
  );
  
  /// Get reward categories
  /// 
  /// Returns [Either<NetworkException, List<CategoryModel>>]
  Future<Either<NetworkException, List<CategoryModel>>> getCategories();
  
  /// Stream of reward categories with real-time updates
  /// 
  /// Returns [Stream<List<CategoryModel>>]
  Stream<List<CategoryModel>> getCategoriesStream();
  
  /// Calculate total points for user
  /// 
  /// Parameters:
  /// - [userId]: User ID to calculate points for
  /// 
  /// Returns [Either<NetworkException, int>] total points
  Future<Either<NetworkException, int>> calculateTotalPoints(String userId);
  
  /// Get reward entries by date range
  /// 
  /// Parameters:
  /// - [userId]: User ID to get rewards for
  /// - [startDate]: Start date for range
  /// - [endDate]: End date for range
  /// 
  /// Returns [Either<NetworkException, List<RewardEntryModel>>]
  Future<Either<NetworkException, List<RewardEntryModel>>> getRewardsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Implementation of FirestoreRewardDataSource using Cloud Firestore.
@LazySingleton(as: FirestoreRewardDataSource)
class FirestoreRewardDataSourceImpl implements FirestoreRewardDataSource {
  final FirebaseFirestore _firestore;
  
  // Collection references
  static const String _rewardEntriesCollection = 'reward_entries';
  static const String _categoriesCollection = 'categories';
  static const String _userStatsCollection = 'user_stats';
  
  // Stream controllers for managing subscriptions
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  
  FirestoreRewardDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<List<RewardEntryModel>> getRewardEntriesStream({
    required String userId,
    String? categoryId,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(_rewardEntriesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return RewardEntryModel.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      log('Error creating reward entries stream: $e', name: 'FirestoreRewardDataSource');
      return Stream.error(NetworkException('Failed to create reward entries stream: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, List<RewardEntryModel>>> getRewardEntries({
    required String userId,
    String? categoryId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_rewardEntriesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final QuerySnapshot snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Query timeout'),
      );
      
      final List<RewardEntryModel> entries = snapshot.docs.map((doc) {
        return RewardEntryModel.fromFirestore(doc);
      }).toList();
      
      log('Retrieved ${entries.length} reward entries for user: $userId', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(entries);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get reward entries: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, RewardEntryModel>> addRewardEntry(
    RewardEntryModel rewardEntry,
  ) async {
    try {
      final batch = _firestore.batch();
      
      // Add reward entry
      final entryRef = _firestore.collection(_rewardEntriesCollection).doc();
      final entryWithId = rewardEntry.copyWith(id: entryRef.id);
      batch.set(entryRef, entryWithId.toFirestore());
      
      // Update user stats atomically
      final userStatsRef = _firestore
          .collection(_userStatsCollection)
          .doc(rewardEntry.userId);
      
      batch.update(userStatsRef, {
        'totalPoints': FieldValue.increment(rewardEntry.points),
        'totalEntries': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Batch commit timeout'),
      );
      
      log('Added reward entry: ${entryWithId.id} (${rewardEntry.points} points)', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(entryWithId);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to add reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, RewardEntryModel>> updateRewardEntry(
    RewardEntryModel rewardEntry,
  ) async {
    try {
      // Get current entry to calculate point difference
      final currentDoc = await _firestore
          .collection(_rewardEntriesCollection)
          .doc(rewardEntry.id)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Get document timeout'),
          );
      
      if (!currentDoc.exists) {
        return Either.left(NetworkException('Reward entry not found'));
      }
      
      final currentEntry = RewardEntryModel.fromFirestore(currentDoc);
      
      final pointsDifference = rewardEntry.points - currentEntry.points;
      
      final batch = _firestore.batch();
      
      // Update reward entry
      final entryRef = _firestore.collection(_rewardEntriesCollection).doc(rewardEntry.id);
      final updatedEntry = rewardEntry.copyWith(
        version: rewardEntry.version + 1,
      );
      batch.update(entryRef, updatedEntry.toFirestore());
      
      // Update user stats if points changed
      if (pointsDifference != 0) {
        final userStatsRef = _firestore
            .collection(_userStatsCollection)
            .doc(rewardEntry.userId);
        
        batch.update(userStatsRef, {
          'totalPoints': FieldValue.increment(pointsDifference),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Batch commit timeout'),
      );
      
      log('Updated reward entry: ${rewardEntry.id} (${pointsDifference > 0 ? '+' : ''}$pointsDifference points)', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(updatedEntry);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to update reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, void>> deleteRewardEntry(String entryId) async {
    try {
      // Get entry to calculate points to subtract
      final doc = await _firestore
          .collection(_rewardEntriesCollection)
          .doc(entryId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Get document timeout'),
          );
      
      if (!doc.exists) {
        return Either.left(NetworkException('Reward entry not found'));
      }
      
      final entry = RewardEntryModel.fromFirestore(doc);
      
      final batch = _firestore.batch();
      
      // Delete reward entry
      batch.delete(doc.reference);
      
      // Update user stats
      final userStatsRef = _firestore
          .collection(_userStatsCollection)
          .doc(entry.userId);
      
      batch.update(userStatsRef, {
        'totalPoints': FieldValue.increment(-entry.points),
        'totalEntries': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Batch commit timeout'),
      );
      
      log('Deleted reward entry: $entryId (-${entry.points} points)', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(null);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to delete reward entry: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, List<RewardEntryModel>>> batchUpdateEntries(
    List<RewardEntryModel> entries,
  ) async {
    if (entries.isEmpty) {
      return Either.right([]);
    }
    
    try {
      final batch = _firestore.batch();
      final updatedEntries = <RewardEntryModel>[];
      
      // Process entries in batches of 500 (Firestore limit)
      const batchSize = 500;
      
      for (int i = 0; i < entries.length; i += batchSize) {
        final batchEntries = entries.skip(i).take(batchSize).toList();
        
        for (final entry in batchEntries) {
          final entryRef = _firestore.collection(_rewardEntriesCollection).doc(entry.id);
          final updatedEntry = entry.copyWith(version: entry.version + 1);
          batch.update(entryRef, updatedEntry.toFirestore());
          updatedEntries.add(updatedEntry);
        }
        
        await batch.commit().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Batch commit timeout'),
        );
      }
      
      log('Batch updated ${entries.length} reward entries', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(updatedEntries);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to batch update entries: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, List<CategoryModel>>> getCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_categoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Query timeout'),
          );
      
      final List<CategoryModel> categories = snapshot.docs.map((doc) {
        return CategoryModel.fromFirestore(doc);
      }).toList();
      
      log('Retrieved ${categories.length} categories', name: 'FirestoreRewardDataSource');
      
      return Either.right(categories);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get categories: ${e.toString()}'));
    }
  }
  
  @override
  Stream<List<CategoryModel>> getCategoriesStream() {
    try {
      return _firestore
          .collection(_categoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      log('Error creating categories stream: $e', name: 'FirestoreRewardDataSource');
      return Stream.error(NetworkException('Failed to create categories stream: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, int>> calculateTotalPoints(String userId) async {
    try {
      // Try to get cached total from user stats first
      final userStatsDoc = await _firestore
          .collection(_userStatsCollection)
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Get user stats timeout'),
          );
      
      if (userStatsDoc.exists) {
        final data = userStatsDoc.data()!;
        final totalPoints = data['totalPoints'] as int? ?? 0;
        
        log('Retrieved cached total points for user $userId: $totalPoints', 
            name: 'FirestoreRewardDataSource');
        
        return Either.right(totalPoints);
      }
      
      // Fallback to aggregation query
      final AggregateQuerySnapshot aggregateQuery = await _firestore
          .collection(_rewardEntriesCollection)
          .where('userId', isEqualTo: userId)
          .aggregate(sum('points'))
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Aggregate query timeout'),
          );
      
      final totalPoints = aggregateQuery.getSum('points')?.toInt() ?? 0;
      
      // Cache the result in user stats
      await _firestore.collection(_userStatsCollection).doc(userId).set({
        'totalPoints': totalPoints,
        'lastCalculated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      log('Calculated and cached total points for user $userId: $totalPoints', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(totalPoints);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to calculate total points: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, List<RewardEntryModel>>> getRewardsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_rewardEntriesCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Date range query timeout'),
          );
      
      final List<RewardEntryModel> entries = snapshot.docs.map((doc) {
        return RewardEntryModel.fromFirestore(doc);
      }).toList();
      
      log('Retrieved ${entries.length} reward entries for date range ${startDate.toIso8601String()} - ${endDate.toIso8601String()}', 
          name: 'FirestoreRewardDataSource');
      
      return Either.right(entries);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get rewards by date range: ${e.toString()}'));
    }
  }
  
  /// Handle Firebase exceptions with proper error mapping
  NetworkException _handleFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return NetworkException('Access denied. Please check your permissions.');
      case 'unavailable':
        return NetworkException('Service temporarily unavailable. Please try again.');
      case 'deadline-exceeded':
        return NetworkException.timeout();
      case 'resource-exhausted':
        return NetworkException('Service quota exceeded. Please try again later.');
      case 'not-found':
        return NetworkException('Requested data not found.');
      case 'already-exists':
        return NetworkException('Data already exists.');
      case 'invalid-argument':
        return NetworkException('Invalid request parameters.');
      case 'failed-precondition':
        return NetworkException('Operation failed due to system state.');
      case 'aborted':
        return NetworkException('Operation was aborted due to a concurrency issue.');
      case 'out-of-range':
        return NetworkException('Request parameters are out of valid range.');
      case 'unimplemented':
        return NetworkException('Operation is not supported.');
      case 'internal':
        return NetworkException('Internal server error occurred.');
      case 'data-loss':
        return NetworkException('Data corruption detected.');
      default:
        return NetworkException('Firestore error: ${e.message ?? e.code}');
    }
  }
  
  /// Dispose resources and close stream subscriptions
  void dispose() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
  }
}

/// Timeout exception for Firestore operations
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}
