import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/task_service.dart';
import '../services/family_service.dart';
import '../theme/theme_service.dart';
import '../network/network_info.dart';
import '../network/connectivity_service.dart';
import '../config/firebase_config.dart' as config;

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Configure dependency injection with proper Firebase initialization
Future<void> configureDependencies() async {
  // Register non-Firebase services first so UI widgets can function
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<NetworkInfo>(() => ConnectivityService(getIt<Connectivity>()));
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());

  // Try initializing Firebase (best-effort, handled internally)
  await FirebaseService.initialize(config.Environment.development);

  // Register Firebase services (only after Firebase.initializeApp)
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Configure GoogleSignIn
  if (kIsWeb) {
    getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
          clientId: 'your-web-client-id.apps.googleusercontent.com', // Placeholder for testing
        ));
  } else {
    getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  }

  // App services
  getIt.registerLazySingleton<UserService>(() => UserService());
  getIt.registerLazySingleton<TaskService>(() => TaskService());
  getIt.registerLazySingleton<FamilyService>(() => FamilyService());

  // Initialize core app services
  await AuthService.initialize();
  await getIt<ThemeService>().initialize();
  await getIt<FamilyService>().initialize();
}

/// Reset all registrations (useful for testing)
void resetDependencies() {
  getIt.reset();
}