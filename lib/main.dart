import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/injection/injection.dart';
import 'core/services/auth_service.dart';
import 'core/models/user_model.dart';
import 'core/theme/theme_service.dart';
import 'shared/widgets/network_status_indicator.dart';
import 'features/auth/login_screen.dart';
import 'features/main/main_app_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('🚀 Starting AI Rewards App...');
    
    // Initialize Hive for local storage
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized');
    
    // Initialize dependency injection with error handling
    try {
      await configureDependencies();
      debugPrint('✅ Dependency injection configured');
    } catch (e) {
      debugPrint('⚠️ Dependency injection failed: $e');
      // Continue without services for now
    }
    
    debugPrint('🎯 Launching main app...');
    runApp(const AIRewardsApp());
  } catch (e) {
    debugPrint('❌ App initialization failed: $e');
    
    // Run minimal fallback app
    runApp(MaterialApp(
      title: 'AI Rewards System - Fallback',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AI Rewards - Debug Mode'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 80, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'App initialization failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Running in fallback mode'),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    ));
  }
}

/// Navigation service for global navigation
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class AIRewardsApp extends StatefulWidget {
  const AIRewardsApp({super.key});

  @override
  State<AIRewardsApp> createState() => _AIRewardsAppState();
}

class _AIRewardsAppState extends State<AIRewardsApp> {
  ThemeService? _themeService;

  @override
  void initState() {
    super.initState();
    try {
      _themeService = getIt<ThemeService>();
      _themeService?.addListener(_onThemeChanged);
    } catch (e) {
      debugPrint('Failed to get ThemeService: $e');
    }
  }

  @override
  void dispose() {
    _themeService?.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building AIRewardsApp MaterialApp...');
    
    return MaterialApp(
      title: 'AI Rewards System',
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeService?.themeMode ?? ThemeMode.system,
      home: const SimpleAuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Authentication wrapper that checks for existing authentication
class SimpleAuthWrapper extends StatefulWidget {
  const SimpleAuthWrapper({super.key});

  @override
  State<SimpleAuthWrapper> createState() => _SimpleAuthWrapperState();
}

class _SimpleAuthWrapperState extends State<SimpleAuthWrapper> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Wait a moment for AuthService to initialize if needed
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('🔐 Checking authentication state...');
      
      // Check if user is already authenticated
      final isAuthenticated = AuthService.isAuthenticated;
      debugPrint('🔐 Authentication state: $isAuthenticated');
      
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Auth check failed: $e');
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      debugPrint('🔐 Building AuthWrapper - checking authentication...');
      return const SplashScreen();
    }

    return StreamBuilder<UserModel?>(
      stream: AuthService.userStream,
      builder: (context, snapshot) {
        debugPrint('🔐 Auth stream state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting && !AuthService.isAuthenticated) {
          return const SplashScreen();
        }

        final user = snapshot.data ?? AuthService.currentUser;
        
        if (user != null) {
          debugPrint('🔐 User authenticated: ${user.displayName} (${user.email})');
          return const MainAppScreen();
        } else {
          debugPrint('🔐 No user authenticated - showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}

/// Splash screen shown during initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Network status indicator
              Align(
                alignment: Alignment.topRight,
                child: NetworkStatusIndicator(),
              ),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 100,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'AI Rewards System',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


