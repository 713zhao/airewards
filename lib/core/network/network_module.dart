import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Network module for dependency injection
@module
abstract class NetworkModule {
  
  /// Provide Connectivity instance
  @lazySingleton
  Connectivity get connectivity => Connectivity();
}