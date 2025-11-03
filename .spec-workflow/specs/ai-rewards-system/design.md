# AI Rewards System - Design Specification

## 1. Architecture Overview

### 1.1 High-Level Architecture

The AI Rewards System follows a clean architecture pattern with clear separation of concerns, ensuring maintainability, testability, and scalability. The architecture consists of the following layers:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
├─────────────────────────────────────────────────────────┤
│                    Application Layer                     │
├─────────────────────────────────────────────────────────┤
│                     Domain Layer                        │
├─────────────────────────────────────────────────────────┤
│                Infrastructure Layer                      │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Technology Stack

#### Frontend Framework
- **Flutter 3.24+**: Cross-platform mobile development
- **Dart 3.5+**: Programming language
- **Material Design 3**: UI/UX framework

#### Backend Services
- **Firebase Authentication**: User authentication and authorization
- **Cloud Firestore**: NoSQL document database
- **Firebase Analytics**: User behavior tracking
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Performance**: App performance monitoring

#### Local Storage
- **SQLite**: Offline data storage via `sqflite` package
- **Hive**: Key-value storage for app preferences
- **Shared Preferences**: Simple key-value storage

#### State Management
- **Bloc Pattern**: Using `flutter_bloc` package for predictable state management
- **Provider**: Dependency injection and service location

#### Additional Services
- **Google AdMob**: Advertisement integration
- **Google Sign-In**: Google OAuth authentication
- **Local Notifications**: `flutter_local_notifications`

## 2. System Architecture

### 2.1 Clean Architecture Implementation

```
lib/
├── main.dart                           # Application entry point
├── core/                              # Core utilities and base classes
│   ├── constants/                     # App constants and configurations
│   ├── errors/                        # Error handling and exceptions
│   ├── network/                       # Network utilities and connectivity
│   ├── services/                      # Core services (DI, logging, etc.)
│   ├── theme/                         # App theming and styles
│   └── utils/                         # Utility functions and helpers
├── features/                          # Feature-based modules
│   ├── authentication/                # Authentication feature
│   │   ├── data/                      # Data layer (repositories, data sources)
│   │   ├── domain/                    # Domain layer (entities, use cases)
│   │   └── presentation/              # Presentation layer (UI, bloc)
│   ├── rewards/                       # Reward management feature
│   ├── redemption/                    # Redemption feature
│   ├── categories/                    # Category management feature
│   ├── history/                       # History tracking feature
│   ├── profile/                       # User profile feature
│   └── advertisements/                # AdMob integration feature
└── shared/                           # Shared components and widgets
    ├── widgets/                       # Reusable UI components
    ├── models/                        # Shared data models
    └── services/                      # Shared services
```

### 2.2 Data Flow Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   UI/Bloc   │───▶│  Use Cases  │───▶│ Repository  │
└─────────────┘    └─────────────┘    └─────────────┘
       ▲                                      │
       │                                      ▼
┌─────────────┐                       ┌─────────────┐
│   States    │◀──────────────────────│Data Sources │
└─────────────┘                       └─────────────┘
                                              │
                                              ▼
                                  ┌─────────────────────┐
                                  │  Firebase/SQLite    │
                                  └─────────────────────┘
```

## 3. Feature Design Specifications

### 3.1 Authentication System

#### 3.1.1 Authentication Flow
```dart
// Domain Entity
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime lastLoginAt;
}

// Authentication States
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState { final User user; }
class AuthFailure extends AuthState { final String message; }
class AuthUnauthenticated extends AuthState {}
```

#### 3.1.2 Authentication Repository Interface
```dart
abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithEmail(String email, String password);
  Future<Either<Failure, User>> signUpWithEmail(String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User?>> getCurrentUser();
  Stream<User?> get authStateChanges;
}
```

#### 3.1.3 Offline Authentication Strategy
- Cache user authentication tokens securely using Flutter Secure Storage
- Store basic user profile data locally for offline access
- Implement token refresh mechanism when connectivity is restored
- Provide guest mode for offline-only usage with data sync on sign-in

### 3.2 Reward Points Management System

#### 3.2.1 Reward Domain Model
```dart
class RewardEntry {
  final String id;
  final String userId;
  final int points;
  final String description;
  final String categoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final RewardType type; // EARNED, ADJUSTED, BONUS
}

class RewardCategory {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final bool isDefault;
  final DateTime createdAt;
}
```

#### 3.2.2 Reward Repository Interface
```dart
abstract class RewardRepository {
  Future<Either<Failure, List<RewardEntry>>> getRewardHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });
  Future<Either<Failure, RewardEntry>> addRewardEntry(RewardEntry entry);
  Future<Either<Failure, RewardEntry>> updateRewardEntry(RewardEntry entry);
  Future<Either<Failure, void>> deleteRewardEntry(String entryId);
  Future<Either<Failure, int>> getTotalPoints(String userId);
  Stream<int> watchTotalPoints(String userId);
}
```

#### 3.2.3 Offline Data Strategy
- Use SQLite as local database with auto-sync capabilities
- Implement conflict resolution for concurrent edits
- Queue offline changes for synchronization when online
- Maintain data integrity with transaction-based operations

### 3.3 Redemption System

#### 3.3.1 Redemption Domain Model
```dart
class RedemptionOption {
  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final String categoryId;
  final bool isActive;
  final DateTime? expiryDate;
  final String? imageUrl;
}

class RedemptionTransaction {
  final String id;
  final String userId;
  final String optionId;
  final int pointsUsed;
  final DateTime redeemedAt;
  final RedemptionStatus status;
  final String? notes;
}

enum RedemptionStatus { PENDING, COMPLETED, CANCELLED, EXPIRED }
```

#### 3.3.2 Redemption Repository Interface
```dart
abstract class RedemptionRepository {
  Future<Either<Failure, List<RedemptionOption>>> getRedemptionOptions();
  Future<Either<Failure, RedemptionTransaction>> redeemPoints(RedemptionRequest request);
  Future<Either<Failure, List<RedemptionTransaction>>> getRedemptionHistory(String userId);
  Future<Either<Failure, bool>> canRedeem(String userId, int points);
}
```

### 3.4 Category Management System

#### 3.4.1 Category Domain Model
```dart
class CategoryManager {
  static const List<RewardCategory> defaultCategories = [
    RewardCategory(id: 'fitness', name: 'Fitness', color: Colors.green),
    RewardCategory(id: 'work', name: 'Work', color: Colors.blue),
    RewardCategory(id: 'personal', name: 'Personal', color: Colors.orange),
    RewardCategory(id: 'bonus', name: 'Bonus', color: Colors.purple),
  ];
}
```

#### 3.4.2 Category Repository Interface
```dart
abstract class CategoryRepository {
  Future<Either<Failure, List<RewardCategory>>> getRewardCategories();
  Future<Either<Failure, List<RedemptionCategory>>> getRedemptionCategories();
  Future<Either<Failure, RewardCategory>> addRewardCategory(RewardCategory category);
  Future<Either<Failure, RewardCategory>> updateRewardCategory(RewardCategory category);
  Future<Either<Failure, void>> deleteRewardCategory(String categoryId);
}
```

## 4. User Interface Design

### 4.1 Navigation Architecture

#### 4.1.1 Bottom Navigation Structure
```dart
enum BottomNavItem {
  dashboard(icon: Icons.dashboard, label: 'Dashboard'),
  rewards(icon: Icons.stars, label: 'Rewards'),
  redemption(icon: Icons.shopping_cart, label: 'Redeem'),
  history(icon: Icons.history, label: 'History'),
  profile(icon: Icons.person, label: 'Profile');
}
```

#### 4.1.2 Screen Hierarchy
```
┌─────────────────────────────────────────┐
│            Splash Screen                │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Authentication Flow             │
├─────────────────────────────────────────┤
│  ├── Login Screen                       │
│  ├── Register Screen                    │
│  ├── Forgot Password Screen             │
│  └── Biometric Setup Screen             │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│            Main App Shell               │
├─────────────────────────────────────────┤
│  ├── Dashboard                          │
│  │   ├── Points Summary                 │
│  │   ├── Recent Activity               │
│  │   ├── Quick Actions                 │
│  │   └── Achievement Cards             │
│  │                                     │
│  ├── Rewards Management                │
│  │   ├── Add Reward Screen             │
│  │   ├── Edit Reward Screen            │
│  │   └── Reward Categories             │
│  │                                     │
│  ├── Redemption                        │
│  │   ├── Available Rewards             │
│  │   ├── Redemption Confirmation       │
│  │   └── Redemption Categories         │
│  │                                     │
│  ├── History                           │
│  │   ├── Reward History                │
│  │   ├── Redemption History            │
│  │   └── Export Options                │
│  │                                     │
│  └── Profile                           │
│      ├── User Settings                 │
│      ├── Category Management           │
│      ├── Backup & Sync                 │
│      └── About & Support               │
└─────────────────────────────────────────┘
```

### 4.2 UI Component Design System

#### 4.2.1 Core Components
```dart
// Custom App Bar with AdMob integration
class RewardsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showAd;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showAd) const AdBannerWidget(),
        AppBar(title: Text(title), actions: actions),
      ],
    );
  }
}

// Reward Card Component
class RewardCard extends StatelessWidget {
  final RewardEntry reward;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}

// Points Display Widget
class PointsDisplayWidget extends StatelessWidget {
  final int totalPoints;
  final int availablePoints;
  final bool showAnimation;
}

// Category Chip Widget
class CategoryChip extends StatelessWidget {
  final RewardCategory category;
  final bool isSelected;
  final VoidCallback? onSelected;
}
```

#### 4.2.2 Theme Configuration
```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32), // Green primary
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50), // Light green primary
      brightness: Brightness.dark,
    ),
  );
}
```

## 5. Database Design

### 5.1 Firebase Firestore Schema

#### 5.1.1 Collections Structure
```
users/
├── {userId}/
│   ├── profile: UserProfile
│   ├── settings: UserSettings
│   └── subcollections/
│       ├── rewards/
│       │   └── {rewardId}: RewardEntry
│       ├── redemptions/
│       │   └── {redemptionId}: RedemptionTransaction
│       ├── categories/
│       │   └── {categoryId}: RewardCategory
│       └── achievements/
│           └── {achievementId}: Achievement

global/
├── redemption_options/
│   └── {optionId}: RedemptionOption
├── default_categories/
│   └── {categoryId}: RewardCategory
└── app_config/
    └── settings: AppConfiguration
```

#### 5.1.2 Document Schemas
```dart
// Firestore Document Schemas
class FirestoreSchemas {
  static Map<String, dynamic> userProfile(User user) => {
    'uid': user.id,
    'email': user.email,
    'displayName': user.displayName,
    'photoUrl': user.photoUrl,
    'provider': user.provider.name,
    'totalPoints': 0,
    'availablePoints': 0,
    'createdAt': FieldValue.serverTimestamp(),
    'lastLoginAt': FieldValue.serverTimestamp(),
    'settings': {
      'notifications': true,
      'theme': 'system',
      'language': 'en',
      'biometricAuth': false,
    }
  };

  static Map<String, dynamic> rewardEntry(RewardEntry entry) => {
    'points': entry.points,
    'description': entry.description,
    'categoryId': entry.categoryId,
    'type': entry.type.name,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': entry.updatedAt?.millisecondsSinceEpoch,
  };

  static Map<String, dynamic> redemptionTransaction(RedemptionTransaction transaction) => {
    'optionId': transaction.optionId,
    'pointsUsed': transaction.pointsUsed,
    'status': transaction.status.name,
    'redeemedAt': FieldValue.serverTimestamp(),
    'notes': transaction.notes,
  };
}
```

### 5.2 Local SQLite Schema

#### 5.2.1 Database Tables
```sql
-- Users table for offline authentication
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    photo_url TEXT,
    provider TEXT NOT NULL,
    total_points INTEGER DEFAULT 0,
    available_points INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    last_login_at INTEGER NOT NULL,
    is_synced INTEGER DEFAULT 0
);

-- Reward entries table
CREATE TABLE reward_entries (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    points INTEGER NOT NULL,
    description TEXT NOT NULL,
    category_id TEXT NOT NULL,
    type TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER,
    is_synced INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Reward categories table
CREATE TABLE reward_categories (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    name TEXT NOT NULL,
    color INTEGER NOT NULL,
    icon_code INTEGER NOT NULL,
    is_default INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    is_synced INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Redemption options table (cached from Firestore)
CREATE TABLE redemption_options (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    required_points INTEGER NOT NULL,
    category_id TEXT,
    is_active INTEGER DEFAULT 1,
    expiry_date INTEGER,
    image_url TEXT,
    last_synced INTEGER NOT NULL
);

-- Redemption transactions table
CREATE TABLE redemption_transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    option_id TEXT NOT NULL,
    points_used INTEGER NOT NULL,
    status TEXT NOT NULL,
    redeemed_at INTEGER NOT NULL,
    notes TEXT,
    is_synced INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Sync queue table for offline operations
CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    data TEXT, -- JSON data for INSERT/UPDATE
    created_at INTEGER NOT NULL,
    retry_count INTEGER DEFAULT 0,
    last_error TEXT
);
```

## 6. Integration Design

### 6.1 Google AdMob Integration

#### 6.1.1 Ad Placement Strategy
```dart
class AdManager {
  static const String appId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
  static const String bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Banner ads on top of main screens
  static const List<String> bannerScreens = [
    '/dashboard',
    '/rewards',
    '/redemption',
    '/history',
  ];

  // Interstitial ads on specific actions
  static const Map<String, int> interstitialTriggers = {
    'redemption_complete': 3, // Show after every 3rd redemption
    'reward_milestone': 1000, // Show when reaching point milestones
  };
}

class AdBannerWidget extends StatefulWidget {
  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return Container(
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
```

### 6.2 Firebase Services Integration

#### 6.2.1 Authentication Service
```dart
class FirebaseAuthService implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return Left(AuthFailure('Sign in cancelled'));

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      final user = _mapFirebaseUser(userCredential.user!);
      await _syncUserProfile(user);
      
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges()
        .map((firebaseUser) => firebaseUser != null 
            ? _mapFirebaseUser(firebaseUser) 
            : null);
  }
}
```

#### 6.2.2 Firestore Service
```dart
class FirestoreService {
  final FirebaseFirestore _firestore;
  
  Future<void> addRewardEntry(String userId, RewardEntry entry) async {
    final batch = _firestore.batch();
    
    // Add reward entry
    final rewardRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('rewards')
        .doc(entry.id);
    batch.set(rewardRef, FirestoreSchemas.rewardEntry(entry));
    
    // Update user points
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'totalPoints': FieldValue.increment(entry.points),
      'availablePoints': FieldValue.increment(entry.points),
    });
    
    await batch.commit();
  }

  Stream<int> watchUserPoints(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['availablePoints'] ?? 0);
  }
}
```

### 6.3 Offline Synchronization

#### 6.3.1 Sync Service Architecture
```dart
class SyncService {
  final FirestoreService _firestoreService;
  final LocalDatabaseService _localDbService;
  final ConnectivityService _connectivityService;

  Future<void> syncAllData() async {
    if (!await _connectivityService.hasConnection()) return;

    try {
      // Sync pending local changes to Firestore
      await _syncLocalToRemote();
      
      // Pull latest data from Firestore
      await _syncRemoteToLocal();
      
      // Clean up successfully synced items
      await _cleanupSyncQueue();
    } catch (e) {
      // Log error and schedule retry
      await _scheduleRetry();
    }
  }

  Future<void> _syncLocalToRemote() async {
    final pendingSync = await _localDbService.getPendingSyncItems();
    
    for (final item in pendingSync) {
      try {
        switch (item.operation) {
          case SyncOperation.INSERT:
            await _firestoreService.insertRecord(item);
            break;
          case SyncOperation.UPDATE:
            await _firestoreService.updateRecord(item);
            break;
          case SyncOperation.DELETE:
            await _firestoreService.deleteRecord(item);
            break;
        }
        await _localDbService.markSynced(item.id);
      } catch (e) {
        await _localDbService.incrementRetryCount(item.id, e.toString());
      }
    }
  }
}
```

## 7. Security Design

### 7.1 Data Encryption

#### 7.1.1 Local Data Security
```dart
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: IOSAccessibility.first_unlock_this_device,
  );

  Future<void> storeAuthToken(String token) async {
    await _secureStorage.write(
      key: 'auth_token',
      value: token,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<void> storeBiometricKey(String key) async {
    await _secureStorage.write(
      key: 'biometric_key',
      value: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
```

#### 7.1.2 Network Security
```dart
class NetworkSecurityConfig {
  static final Dio dio = Dio()
    ..interceptors.addAll([
      LogInterceptor(responseBody: false),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer ${AuthService.token}';
          handler.next(options);
        },
      ),
    ]);

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### 7.2 Biometric Authentication

#### 7.2.1 Biometric Service Implementation
```dart
class BiometricAuthService {
  final LocalAuthentication _localAuth;

  Future<bool> isBiometricAvailable() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your rewards',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }
}
```

## 8. Performance Optimization

### 8.1 State Management Optimization

#### 8.1.1 Bloc Optimization Patterns
```dart
// Optimized Reward Bloc with debouncing and caching
class RewardBloc extends Bloc<RewardEvent, RewardState> {
  final RewardRepository _repository;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  Stream<RewardState> mapEventToState(RewardEvent event) async* {
    if (event is LoadRewards) {
      yield* _mapLoadRewardsToState(event);
    } else if (event is SearchRewards) {
      yield* _mapSearchRewardsToState(event);
    }
  }

  Stream<RewardState> _mapSearchRewardsToState(SearchRewards event) async* {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      add(LoadRewards(searchQuery: event.query));
    });
  }
}
```

### 8.2 Database Optimization

#### 8.2.1 SQLite Indexing Strategy
```sql
-- Performance indexes
CREATE INDEX idx_reward_entries_user_created 
ON reward_entries(user_id, created_at DESC);

CREATE INDEX idx_reward_entries_category 
ON reward_entries(category_id);

CREATE INDEX idx_redemption_transactions_user_date 
ON redemption_transactions(user_id, redeemed_at DESC);

CREATE INDEX idx_sync_queue_status 
ON sync_queue(table_name, operation, created_at);
```

#### 8.2.2 Pagination Implementation
```dart
class PaginatedRewardRepository extends RewardRepository {
  static const int pageSize = 20;

  @override
  Future<Either<Failure, PaginatedResult<RewardEntry>>> getRewardHistory({
    int page = 1,
    String? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final rewards = await _localDbService.getRewards(
        limit: pageSize,
        offset: offset,
        categoryFilter: categoryFilter,
        startDate: startDate,
        endDate: endDate,
      );
      
      final totalCount = await _localDbService.getRewardsCount(
        categoryFilter: categoryFilter,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(PaginatedResult(
        items: rewards,
        totalCount: totalCount,
        currentPage: page,
        hasNextPage: totalCount > page * pageSize,
      ));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
```

## 9. Testing Strategy

### 9.1 Unit Testing Architecture

#### 9.1.1 Test Structure
```dart
// Example: Reward Bloc Test
class MockRewardRepository extends Mock implements RewardRepository {}

void main() {
  group('RewardBloc', () {
    late RewardBloc rewardBloc;
    late MockRewardRepository mockRepository;

    setUp(() {
      mockRepository = MockRewardRepository();
      rewardBloc = RewardBloc(mockRepository);
    });

    blocTest<RewardBloc, RewardState>(
      'emits [RewardLoading, RewardLoaded] when LoadRewards is added',
      build: () {
        when(() => mockRepository.getRewardHistory())
            .thenAnswer((_) async => Right(mockRewardList));
        return rewardBloc;
      },
      act: (bloc) => bloc.add(const LoadRewards()),
      expect: () => [
        const RewardLoading(),
        RewardLoaded(mockRewardList),
      ],
    );
  });
}
```

### 9.2 Integration Testing

#### 9.2.1 Firebase Testing Setup
```dart
class TestFirebaseService {
  static Future<void> setupFirebaseEmulator() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
}
```

## 10. Deployment Architecture

### 10.1 CI/CD Pipeline

#### 10.1.1 GitHub Actions Configuration
```yaml
name: Flutter CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build_android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build_ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
```

### 10.2 Environment Configuration

#### 10.2.1 Environment Management
```dart
enum Environment { development, staging, production }

class AppConfig {
  static const Environment environment = Environment.development;
  
  static const Map<Environment, AppSettings> _config = {
    Environment.development: AppSettings(
      apiBaseUrl: 'https://dev-api.example.com',
      firebaseProject: 'ai-rewards-dev',
      admobAppId: 'ca-app-pub-3940256099942544~3347511713', // Test ID
    ),
    Environment.staging: AppSettings(
      apiBaseUrl: 'https://staging-api.example.com',
      firebaseProject: 'ai-rewards-staging',
      admobAppId: 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX',
    ),
    Environment.production: AppSettings(
      apiBaseUrl: 'https://api.example.com',
      firebaseProject: 'ai-rewards-prod',
      admobAppId: 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX',
    ),
  };

  static AppSettings get current => _config[environment]!;
}
```

---

**Document Version**: 1.0  
**Last Updated**: October 30, 2025  
**Status**: Draft - Pending Approval  
**Dependencies**: Requirements Specification v1.0  
**Stakeholders**: Technical Lead, Mobile Development Team, Firebase Team, QA Team