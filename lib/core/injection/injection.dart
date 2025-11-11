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
  // Initialize Firebase first
  await FirebaseService.initialize(config.Environment.development);
  
  // Register Firebase services manually
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  
  // Configure GoogleSignIn
  if (kIsWeb) {
    // For web, use GoogleSignIn with web configuration (placeholder client ID)
    getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
      clientId: 'your-web-client-id.apps.googleusercontent.com', // Placeholder for testing
    ));
  } else {
    getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  }
  
  // Register connectivity services
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<NetworkInfo>(() => ConnectivityService(getIt<Connectivity>()));
  
  // Register theme service
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  
  // Register authentication and user services
  getIt.registerLazySingleton<UserService>(() => UserService());
  
  // Register task service
  getIt.registerLazySingleton<TaskService>(() => TaskService());
  
  // Register family service
  getIt.registerLazySingleton<FamilyService>(() => FamilyService());
  
  // Initialize services
  await AuthService.initialize();
  await getIt<ThemeService>().initialize();
  await getIt<FamilyService>().initialize();
}

/// Reset all registrations (useful for testing)
void resetDependencies() {
  getIt.reset();
}