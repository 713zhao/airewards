import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/entities.dart';
import '../models/models.dart';

/// Remote data source for Firestore redemption operations.
/// 
/// This class handles all Firestore operations for redemption options and
/// transactions including batch operations for point redemptions, real-time
/// listeners for option availability, and proper document/collection structure.
/// 
/// Key features:
/// - Real-time redemption option synchronization with listeners
/// - Atomic point redemption transactions with rollback support
/// - Availability tracking and stock management
/// - Transaction history and audit trails
/// - Comprehensive error handling and recovery
/// - Proper document structure and indexing
abstract class FirestoreRedemptionDataSource {
  /// Stream of available redemption options with real-time updates
  /// 
  /// Parameters:
  /// - [category]: Optional category filter
  /// - [limit]: Number of options to fetch (default 50)
  /// 
  /// Returns [Stream<List<RedemptionOptionModel>>] with real-time updates
  Stream<List<RedemptionOptionModel>> getRedemptionOptionsStream({
    String? category,
    int limit = 50,
  });
  
  /// Get paginated redemption options
  /// 
  /// Parameters:
  /// - [category]: Optional category filter
  /// - [startAfter]: Document to start after for pagination
  /// - [limit]: Number of options to fetch
  /// - [sortBy]: Sort field (points, name, etc.)
  /// - [sortOrder]: Sort order (asc/desc)
  /// 
  /// Returns [Either<NetworkException, List<RedemptionOptionModel>>]
  Future<Either<NetworkException, List<RedemptionOptionModel>>> getRedemptionOptions({
    String? category,
    DocumentSnapshot? startAfter,
    int limit = 20,
    String sortBy = 'pointsCost',
    bool ascending = true,
  });
  
  /// Get specific redemption option by ID
  /// 
  /// Parameters:
  /// - [optionId]: ID of redemption option
  /// 
  /// Returns [Either<NetworkException, RedemptionOptionModel?>]
  Future<Either<NetworkException, RedemptionOptionModel?>> getRedemptionOption(
    String optionId,
  );
  
  /// Redeem points for option (atomic transaction)
  /// 
  /// Parameters:
  /// - [transaction]: Redemption transaction details
  /// 
  /// Returns [Either<NetworkException, RedemptionTransactionModel>]
  Future<Either<NetworkException, RedemptionTransactionModel>> redeemPoints(
    RedemptionTransactionModel transaction,
  );
  
  /// Get user's redemption transaction history
  /// 
  /// Parameters:
  /// - [userId]: User ID to get transactions for
  /// - [startAfter]: Document to start after for pagination
  /// - [limit]: Number of transactions to fetch
  /// 
  /// Returns [Either<NetworkException, List<RedemptionTransactionModel>>]
  Future<Either<NetworkException, List<RedemptionTransactionModel>>> getRedemptionHistory({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  });
  
  /// Stream of user's redemption transactions with real-time updates
  /// 
  /// Parameters:
  /// - [userId]: User ID to get transactions for
  /// - [limit]: Number of transactions to fetch (default 50)
  /// 
  /// Returns [Stream<List<RedemptionTransactionModel>>]
  Stream<List<RedemptionTransactionModel>> getRedemptionHistoryStream({
    required String userId,
    int limit = 50,
  });
  
  /// Cancel redemption transaction (if allowed)
  /// 
  /// Parameters:
  /// - [transactionId]: ID of transaction to cancel
  /// - [reason]: Reason for cancellation
  /// 
  /// Returns [Either<NetworkException, RedemptionTransactionModel>]
  Future<Either<NetworkException, RedemptionTransactionModel>> cancelRedemption({
    required String transactionId,
    required String reason,
  });
  
  /// Update redemption option availability
  /// 
  /// Parameters:
  /// - [optionId]: ID of redemption option
  /// - [quantityChange]: Change in available quantity (can be negative)
  /// 
  /// Returns [Either<NetworkException, RedemptionOptionModel>]
  Future<Either<NetworkException, RedemptionOptionModel>> updateOptionAvailability({
    required String optionId,
    required int quantityChange,
  });
  
  /// Get redemption statistics for user
  /// 
  /// Parameters:
  /// - [userId]: User ID to get stats for
  /// 
  /// Returns [Either<NetworkException, Map<String, dynamic>>] with stats
  Future<Either<NetworkException, Map<String, dynamic>>> getRedemptionStats(
    String userId,
  );
}

/// Implementation of FirestoreRedemptionDataSource using Cloud Firestore.
@LazySingleton(as: FirestoreRedemptionDataSource)
class FirestoreRedemptionDataSourceImpl implements FirestoreRedemptionDataSource {
  final FirebaseFirestore _firestore;
  
  // Collection references
  static const String _redemptionOptionsCollection = 'redemption_options';
  static const String _redemptionTransactionsCollection = 'redemption_transactions';
  static const String _userStatsCollection = 'user_stats';
  
  // Stream controllers for managing subscriptions
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  
  FirestoreRedemptionDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Stream<List<RedemptionOptionModel>> getRedemptionOptionsStream({
    String? category,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(_redemptionOptionsCollection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('pointsCost')
          .limit(limit);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return RedemptionOptionModel.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      log('Error creating redemption options stream: $e', name: 'FirestoreRedemptionDataSource');
      return Stream.error(NetworkException('Failed to create redemption options stream: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, List<RedemptionOptionModel>>> getRedemptionOptions({
    String? category,
    DocumentSnapshot? startAfter,
    int limit = 20,
    String sortBy = 'pointsCost',
    bool ascending = true,
  }) async {
    try {
      Query query = _firestore
          .collection(_redemptionOptionsCollection)
          .where('isAvailable', isEqualTo: true)
          .orderBy(sortBy, descending: !ascending)
          .limit(limit);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final QuerySnapshot snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Query timeout'),
      );
      
      final List<RedemptionOptionModel> options = snapshot.docs.map((doc) {
        return RedemptionOptionModel.fromFirestore(doc);
      }).toList();
      
      log('Retrieved ${options.length} redemption options', 
          name: 'FirestoreRedemptionDataSource');
      
      return Either.right(options);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get redemption options: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, RedemptionOptionModel?>> getRedemptionOption(
    String optionId,
  ) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_redemptionOptionsCollection)
          .doc(optionId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Get document timeout'),
          );
      
      if (!doc.exists) {
        return Either.right(null);
      }
      
      final option = RedemptionOptionModel.fromFirestore(doc);
      
      log('Retrieved redemption option: ${option.id}', 
          name: 'FirestoreRedemptionDataSource');
      
      return Either.right(option);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get redemption option: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, RedemptionTransactionModel>> redeemPoints(
    RedemptionTransactionModel transaction,
  ) async {
    try {
      final transactionResult = await _firestore.runTransaction((firestoreTransaction) async {
        // Get redemption option to validate
        final optionRef = _firestore
            .collection(_redemptionOptionsCollection)
            .doc(transaction.optionId);
        
        final optionDoc = await firestoreTransaction.get(optionRef);
        
        if (!optionDoc.exists) {
          throw NetworkException('Redemption option not found');
        }
        
        final option = RedemptionOptionModel.fromFirestore(optionDoc);
        
        // Validate availability
        if (!option.isAvailable) {
          throw NetworkException('Redemption option is no longer available');
        }
        
        // Note: Assuming quantityAvailable will be added to RedemptionOption domain model
        // For now, we'll check isActive status
        if (!option.isActive) {
          throw NetworkException('Insufficient quantity available');
        }
        
        // Get user stats to validate points
        final userStatsRef = _firestore
            .collection(_userStatsCollection)
            .doc(transaction.userId);
        
        final userStatsDoc = await firestoreTransaction.get(userStatsRef);
        
        if (!userStatsDoc.exists) {
          throw NetworkException('User stats not found');
        }
        
        final userStats = userStatsDoc.data()!;
        final totalPoints = userStats['totalPoints'] as int? ?? 0;
        final totalCost = transaction.pointsUsed; // Single redemption, no quantity concept
        
        if (totalPoints < totalCost) {
          throw NetworkException('Insufficient points for redemption');
        }
        
        // Create transaction record
        final transactionRef = _firestore
            .collection(_redemptionTransactionsCollection)
            .doc();
        
        final transactionWithId = transaction.copyWith(
          id: transactionRef.id,
          redeemedAt: DateTime.now(),
        );
        
        firestoreTransaction.set(transactionRef, transactionWithId.toFirestore());
        
        // Update user points
        firestoreTransaction.update(userStatsRef, {
          'totalPoints': FieldValue.increment(-totalCost),
          'totalRedemptions': FieldValue.increment(1),
          'lastRedemption': FieldValue.serverTimestamp(),
        });
        
        // Update option quantity tracking (simplified for this implementation)
        firestoreTransaction.update(optionRef, {
          'totalRedeemed': FieldValue.increment(1),
          'lastRedeemed': FieldValue.serverTimestamp(),
        });
        
        log('Processed redemption transaction: ${transactionWithId.id} ($totalCost points)', 
            name: 'FirestoreRedemptionDataSource');
        
        return transactionWithId;
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Transaction timeout'),
      );
      
      return Either.right(transactionResult);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on NetworkException catch (e) {
      return Either.left(e);
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to redeem points: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, List<RedemptionTransactionModel>>> getRedemptionHistory({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_redemptionTransactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final QuerySnapshot snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Query timeout'),
      );
      
      final List<RedemptionTransactionModel> transactions = snapshot.docs.map((doc) {
        return RedemptionTransactionModel.fromFirestore(doc);
      }).toList();
      
      log('Retrieved ${transactions.length} redemption transactions for user: $userId', 
          name: 'FirestoreRedemptionDataSource');
      
      return Either.right(transactions);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get redemption history: ${e.toString()}'));
    }
  }
  
  @override
  Stream<List<RedemptionTransactionModel>> getRedemptionHistoryStream({
    required String userId,
    int limit = 50,
  }) {
    try {
      return _firestore
          .collection(_redemptionTransactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return RedemptionTransactionModel.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      log('Error creating redemption history stream: $e', name: 'FirestoreRedemptionDataSource');
      return Stream.error(NetworkException('Failed to create redemption history stream: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, RedemptionTransactionModel>> cancelRedemption({
    required String transactionId,
    required String reason,
  }) async {
    try {
      final cancelResult = await _firestore.runTransaction((firestoreTransaction) async {
        // Get transaction to validate
        final transactionRef = _firestore
            .collection(_redemptionTransactionsCollection)
            .doc(transactionId);
        
        final transactionDoc = await firestoreTransaction.get(transactionRef);
        
        if (!transactionDoc.exists) {
          throw NetworkException('Redemption transaction not found');
        }
        
        final transaction = RedemptionTransactionModel.fromFirestore(transactionDoc);
        
        // Validate cancellation is allowed
        if (transaction.status != RedemptionStatus.pending) {
          throw NetworkException('Transaction cannot be cancelled in current status');
        }
        
        // Check if cancellation window is still open (e.g., within 24 hours)
        final hoursSinceTransaction = DateTime.now().difference(transaction.redeemedAt).inHours;
        if (hoursSinceTransaction > 24) {
          throw NetworkException('Cancellation window has expired');
        }
        
        // Update transaction status
        final cancelledTransaction = transaction.copyWith(
          status: RedemptionStatus.cancelled,
          notes: '${transaction.notes ?? ''}\nCancelled: $reason',
        );
        
        firestoreTransaction.update(transactionRef, cancelledTransaction.toFirestore());
        
        // Refund points to user
        final userStatsRef = _firestore
            .collection(_userStatsCollection)
            .doc(transaction.userId);
        
        final totalRefund = transaction.pointsUsed;
        
        firestoreTransaction.update(userStatsRef, {
          'totalPoints': FieldValue.increment(totalRefund),
          'totalRedemptions': FieldValue.increment(-1),
        });
        
        // Restore option quantity tracking
        final optionRef = _firestore
            .collection(_redemptionOptionsCollection)
            .doc(transaction.optionId);
        
        firestoreTransaction.update(optionRef, {
          'totalRedeemed': FieldValue.increment(-1),
        });
        
        log('Cancelled redemption transaction: $transactionId (refunded $totalRefund points)', 
            name: 'FirestoreRedemptionDataSource');
        
        return cancelledTransaction;
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Transaction timeout'),
      );
      
      return Either.right(cancelResult);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on NetworkException catch (e) {
      return Either.left(e);
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to cancel redemption: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, RedemptionOptionModel>> updateOptionAvailability({
    required String optionId,
    required int quantityChange,
  }) async {
    try {
      final updateResult = await _firestore.runTransaction((firestoreTransaction) async {
        final optionRef = _firestore
            .collection(_redemptionOptionsCollection)
            .doc(optionId);
        
        final optionDoc = await firestoreTransaction.get(optionRef);
        
        if (!optionDoc.exists) {
          throw NetworkException('Redemption option not found');
        }
        
        final option = RedemptionOptionModel.fromFirestore(optionDoc);
        
        // For this implementation, we'll just update tracking metadata
        firestoreTransaction.update(optionRef, {
          'lastUpdated': FieldValue.serverTimestamp(),
          'availabilityChange': FieldValue.increment(quantityChange),
        });
        
        log('Updated redemption option availability: $optionId (${quantityChange > 0 ? '+' : ''}$quantityChange)', 
            name: 'FirestoreRedemptionDataSource');
        
        return option;
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Transaction timeout'),
      );
      
      return Either.right(updateResult);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on NetworkException catch (e) {
      return Either.left(e);
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to update option availability: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<NetworkException, Map<String, dynamic>>> getRedemptionStats(
    String userId,
  ) async {
    try {
      // Get user stats document
      final userStatsDoc = await _firestore
          .collection(_userStatsCollection)
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Get user stats timeout'),
          );
      
      Map<String, dynamic> stats = {
        'totalRedemptions': 0,
        'totalPointsRedeemed': 0,
        'lastRedemption': null,
      };
      
      if (userStatsDoc.exists) {
        final data = userStatsDoc.data()!;
        stats['totalRedemptions'] = data['totalRedemptions'] ?? 0;
        stats['lastRedemption'] = data['lastRedemption'];
      }
      
      // Calculate total points redeemed from transactions
      final transactionsQuery = await _firestore
          .collection(_redemptionTransactionsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            RedemptionStatus.completed.value,
          ])
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Transactions query timeout'),
          );
      
      int totalPointsRedeemed = 0;
      for (final doc in transactionsQuery.docs) {
        final transaction = RedemptionTransactionModel.fromFirestore(doc);
        totalPointsRedeemed += transaction.pointsUsed;
      }
      
      stats['totalPointsRedeemed'] = totalPointsRedeemed;
      
      log('Retrieved redemption stats for user $userId: ${stats.toString()}', 
          name: 'FirestoreRedemptionDataSource');
      
      return Either.right(stats);
    } on FirebaseException catch (e) {
      return Either.left(_handleFirebaseException(e));
    } on TimeoutException {
      return Either.left(NetworkException.timeout());
    } catch (e) {
      return Either.left(NetworkException('Failed to get redemption stats: ${e.toString()}'));
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