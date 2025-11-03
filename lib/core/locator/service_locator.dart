import '../injection/injection.dart';
import '../../features/authentication/data/services/auth_service.dart';
import '../services/firebase_service.dart';
import '../network/network_info.dart';
import '../network/network_utils.dart';

/// Service locator helper for easy access to registered services
class ServiceLocator {
  
  // Core Services
  static FirebaseService get firebaseService => getIt<FirebaseService>();
  
  // Network Services
  static NetworkInfo get networkInfo => getIt<NetworkInfo>();
  static NetworkUtils get networkUtils => getIt<NetworkUtils>();
  
  // Feature Services
  static AuthService get authService => getIt<AuthService>();
  
  /// Check if all services are registered
  static bool get isInitialized {
    return getIt.isRegistered<FirebaseService>() &&
           getIt.isRegistered<AuthService>();
  }
  
  /// Register additional services at runtime (for testing)
  static void registerTestService<T extends Object>(T service) {
    if (!getIt.isRegistered<T>()) {
      getIt.registerSingleton<T>(service);
    }
  }
  
  /// Unregister services (for testing)
  static void unregisterService<T extends Object>() {
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
  }
}