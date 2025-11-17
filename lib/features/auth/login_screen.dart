import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/account_type.dart';
import '../../core/theme/theme_extensions.dart';
import '../main/main_app_screen.dart';

/// Login screen for authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  AccountType _selectedAccountType = AccountType.parent;
  
  // Saved accounts for autocomplete
  List<Map<String, String>> _savedAccounts = [];
  List<Map<String, String>> _filteredAccounts = [];
  bool _showAccountSuggestions = false;
  
  // Helpers for consistent, case-insensitive secure storage keys
  String _normalizeEmail(String email) => email.trim().toLowerCase();
  String _normalizedKeyForEmail(String email) => 'pwd_${_normalizeEmail(email)}';
  String _legacyKeyForEmail(String email) => 'pwd_${email.trim()}';
  
  // Web fallback keys (SharedPreferences/localStorage) for Safari limitations
  String _webFallbackKeyForEmail(String email) => 'pwd_web_${_normalizeEmail(email)}';
  

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    // Load saved accounts after first frame to ensure SharedPreferences is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedAccounts();
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Load saved accounts (emails from SharedPreferences, passwords from secure storage)
  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      
      final savedEmails = prefs.getStringList('saved_emails') ?? [];
      
      final accounts = <Map<String, String>>[];
      for (final email in savedEmails) {
        // On web: use SharedPreferences directly for reliability on Safari
        // On mobile: use secure storage
        String password = '';
        if (kIsWeb) {
          password = prefs.getString(_webFallbackKeyForEmail(email)) ?? '';
        } else {
          try {
            password = await secureStorage.read(key: _normalizedKeyForEmail(email)) ?? '';
            if (password.isEmpty) {
              final legacy = await secureStorage.read(key: _legacyKeyForEmail(email)) ?? '';
              if (legacy.isNotEmpty) {
                // Migrate legacy key to normalized key for future reads
                await secureStorage.write(key: _normalizedKeyForEmail(email), value: legacy);
                await secureStorage.delete(key: _legacyKeyForEmail(email));
                password = legacy;
              }
            }
          } catch (_) {
            // ignore
          }
        }
        accounts.add({
          'email': email,
          'password': password,
        });
      }
      
      if (mounted) {
        setState(() {
          _savedAccounts = accounts;
          
          // Load last used email and password
          if (_savedAccounts.isNotEmpty) {
            _emailController.text = _savedAccounts.first['email'] ?? '';
            _passwordController.text = _savedAccounts.first['password'] ?? '';
          }
        });
      }
    } catch (e) {
      // swallow debug logs in release
    }
  }

  /// Save account credentials (email in SharedPreferences, password in secure storage)
  Future<void> _saveAccount(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      
      // Get existing emails
      final savedEmails = prefs.getStringList('saved_emails') ?? [];
      
      // Remove existing entry for this email (case-insensitive)
      savedEmails.removeWhere((e) => e.toLowerCase() == email.trim().toLowerCase());
      
      // Add to beginning (most recent first)
      savedEmails.insert(0, email.trim());
      
      // Keep only last 5 accounts
      if (savedEmails.length > 5) {
        // Remove password from secure storage for the oldest account
        final oldestEmail = savedEmails.last;
        await secureStorage.delete(key: _normalizedKeyForEmail(oldestEmail));
        await secureStorage.delete(key: _legacyKeyForEmail(oldestEmail));
        savedEmails.removeLast();
      }
      
      // Save email list to SharedPreferences
      await prefs.setStringList('saved_emails', savedEmails);
      
      // Save password (web: SharedPreferences; mobile: secure storage)
      if (password.isNotEmpty) {
        if (kIsWeb) {
          await prefs.setString(_webFallbackKeyForEmail(email), password);
        } else {
          try {
            await secureStorage.write(key: _normalizedKeyForEmail(email), value: password);
          } catch (_) {
            // ignore
          }
        }
      } else {
        // Remove password if empty (parent account or OAuth)
        if (kIsWeb) {
          await prefs.remove(_webFallbackKeyForEmail(email));
        } else {
          try {
            await secureStorage.delete(key: _normalizedKeyForEmail(email));
            await secureStorage.delete(key: _legacyKeyForEmail(email));
          } catch (_) {
            // ignore
          }
        }
      }
      
      // Update in-memory list immediately
      if (mounted) {
        setState(() {
          _savedAccounts.removeWhere((account) => account['email'] == email);
          _savedAccounts.insert(0, {
            'email': email,
            'password': password,
          });
          if (_savedAccounts.length > 5) {
            _savedAccounts = _savedAccounts.take(5).toList();
          }
        });
      }
    } catch (e) {
      // swallow debug logs in release
    }
  }

  /// Filter accounts based on email input
  void _onEmailChanged() async {
    final raw = _emailController.text;
    final query = raw.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _showAccountSuggestions = false;
        _filteredAccounts = [];
      });
      return;
    }
    
    final filtered = _savedAccounts.where((account) {
      return account['email']!.toLowerCase().contains(query);
    }).toList();
    
    setState(() {
      _filteredAccounts = filtered;
      _showAccountSuggestions = filtered.isNotEmpty && !_isSignUp;
    });

    // If typed email exactly matches a saved account (case-insensitive), auto-fill password
    final exact = _savedAccounts.where((a) => (a['email'] ?? '').toLowerCase() == query).toList();
    if (exact.isNotEmpty) {
      final account = exact.first;
      var pwd = account['password'] ?? '';
      if (pwd.isEmpty) {
        // Fallback: fetch from storage
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          pwd = prefs.getString(_webFallbackKeyForEmail(raw)) ?? '';
        } else {
          const secureStorage = FlutterSecureStorage();
          try {
            pwd = await secureStorage.read(key: _normalizedKeyForEmail(raw)) ?? '';
          } catch (_) {
            // ignore
          }
        }
      }
      if (pwd.isNotEmpty && mounted) {
        setState(() {
          _passwordController.text = pwd;
        });
      }
    }
  }

  /// Select a saved account
  void _selectAccount(Map<String, String> account) async {
    var email = account['email'] ?? '';
    var password = account['password'] ?? '';
    if (password.isEmpty && email.isNotEmpty) {
      // Fallback to storage if in-memory password is empty
      String fetched = '';
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        fetched = prefs.getString(_webFallbackKeyForEmail(email)) ?? '';
      } else {
        const secureStorage = FlutterSecureStorage();
        try {
          fetched = await secureStorage.read(key: _normalizedKeyForEmail(email)) ?? '';
        } catch (_) {
          // ignore
        }
      }
      if (fetched.isNotEmpty) password = fetched;
    }
    if (mounted) {
      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
        _showAccountSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: context.responsivePadding,
            child: Column(
              children: [
                
                const SizedBox(height: 40),
                
                // App logo and title
                _buildHeader(),
                
                const SizedBox(height: 40),
                
                // Login form
                _buildLoginForm(),
                
                const SizedBox(height: 20),
                
                // Google Sign-In button
                _buildGoogleSignIn(),
                
                const SizedBox(height: 20),
                
                // Toggle sign up/sign in
                _buildToggleMode(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.star,
            size: 50,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AI Rewards System',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp ? 'Create your family account' : 'Welcome back!',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display name field (only for sign up)
              if (_isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Account type selection
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Type',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<AccountType>(
                                value: AccountType.parent,
                                groupValue: _selectedAccountType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAccountType = value!;
                                  });
                                },
                                title: const Text('Parent'),
                                subtitle: const Text('Full management access'),
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<AccountType>(
                                value: AccountType.child,
                                groupValue: _selectedAccountType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAccountType = value!;
                                  });
                                },
                                title: const Text('Child'),
                                subtitle: const Text('Complete tasks & earn rewards'),
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Email field with autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      prefixIcon: const Icon(Icons.email),
                      suffixIcon: _savedAccounts.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_savedAccounts.length}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onPressed: () {
                                    setState(() {
                                      _filteredAccounts = _savedAccounts;
                                      _showAccountSuggestions = !_showAccountSuggestions && !_isSignUp;
                                    });
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  
                  // Account suggestions dropdown
                  if (_showAccountSuggestions && _filteredAccounts.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredAccounts.length,
                        itemBuilder: (context, index) {
                          final account = _filteredAccounts[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              radius: 16,
                              child: Text(
                                account['email']!.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              account['email']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.login, size: 18),
                            onTap: () => _selectAccount(account),
                          );
                        },
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: _isSignUp ? 'Create a password' : 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (_isSignUp && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 8),
              
              // Forgot password link (only for sign in)
              if (!_isSignUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isSignUp ? 'Create Account' : 'Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignIn() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Or continue with'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.all(12),
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              label: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isSignUp ? 'Already have an account?' : "Don't have an account?"),
        TextButton(
          onPressed: _isLoading ? null : () {
            setState(() {
              _isSignUp = !_isSignUp;
              _errorMessage = null;
            });
          },
          child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
        ),
      ],
    );
  }



  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      UserModel? user;
      
      if (_isSignUp) {
        user = await AuthService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          accountType: _selectedAccountType,
        );
      } else {
        user = await AuthService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (user != null && mounted) {
        // Save account credentials: password only for child accounts
        final password = user.accountType == AccountType.child ? _passwordController.text : '';
        debugPrint('💾 Saving account - Email: ${_emailController.text.trim()}, AccountType: ${user.accountType}, Password length: ${password.length}');
        await _saveAccount(_emailController.text.trim(), password);
        _navigateToMainApp();
      } else {
        // no-op
      }
  } catch (e) {
      // ignore stack for user-facing
      setState(() {
        _errorMessage = e.toString().replaceAll('AuthException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        // Save Google account (no password for OAuth)
        if (user.email.isNotEmpty) {
          await _saveAccount(user.email, '');
        }
        _navigateToMainApp();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('AuthException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first';
      });
      return;
    }

    try {
      await AuthService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('AuthException: ', '');
      });
    }
  }



  void _navigateToMainApp() {
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return const MainAppScreen();
          },
        ),
      );
  } catch (e) {
      // ignore navigation errors for now
    }
  }
}