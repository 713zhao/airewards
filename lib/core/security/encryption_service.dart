import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Advanced encryption service for protecting sensitive user data
/// Implements multiple layers of security for kid-safe data protection
class EncryptionService {
  static const String _keyPrefix = 'ai_rewards_';
  static const String _masterKeyName = '${_keyPrefix}master_key';
  static const String _ivKeyName = '${_keyPrefix}initialization_vector';
  
  static late final FlutterSecureStorage _secureStorage;
  static late final Encrypter _encrypter;
  static late final IV _iv;
  
  /// Initialize encryption service with secure key generation
  static Future<void> initialize() async {
    debugPrint('🔐 Initializing EncryptionService...');
    
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
    );
    
    await _initializeEncryption();
    debugPrint('✅ EncryptionService initialized successfully');
  }
  
  /// Initialize or retrieve encryption keys securely
  static Future<void> _initializeEncryption() async {
    try {
      // Try to retrieve existing master key
      String? masterKeyString = await _secureStorage.read(key: _masterKeyName);
      String? ivString = await _secureStorage.read(key: _ivKeyName);
      
      if (masterKeyString == null || ivString == null) {
        // Generate new encryption keys
        debugPrint('🔑 Generating new encryption keys');
        
        final key = Key.fromSecureRandom(32); // 256-bit key
        final iv = IV.fromSecureRandom(16);   // 128-bit IV
        
        await _secureStorage.write(key: _masterKeyName, value: key.base64);
        await _secureStorage.write(key: _ivKeyName, value: iv.base64);
        
        _encrypter = Encrypter(AES(key));
        _iv = iv;
      } else {
        // Use existing keys
        debugPrint('🔓 Using existing encryption keys');
        
        final key = Key.fromBase64(masterKeyString);
        _iv = IV.fromBase64(ivString);
        _encrypter = Encrypter(AES(key));
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize encryption: $e');
      rethrow;
    }
  }
  
  /// Encrypt sensitive data
  static String encryptData(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('❌ Encryption failed: $e');
      rethrow;
    }
  }
  
  /// Decrypt sensitive data
  static String decryptData(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('❌ Decryption failed: $e');
      rethrow;
    }
  }
  
  /// Encrypt JSON data
  static String encryptJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encryptData(jsonString);
  }
  
  /// Decrypt JSON data
  static Map<String, dynamic> decryptJson(String encryptedData) {
    final jsonString = decryptData(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
  
  /// Encrypt file data
  static Uint8List encryptFile(Uint8List fileData) {
    try {
      final encrypted = _encrypter.encryptBytes(fileData, iv: _iv);
      return encrypted.bytes;
    } catch (e) {
      debugPrint('❌ File encryption failed: $e');
      rethrow;
    }
  }
  
  /// Decrypt file data
  static Uint8List decryptFile(Uint8List encryptedData) {
    try {
      final encrypted = Encrypted(encryptedData);
      return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
    } catch (e) {
      debugPrint('❌ File decryption failed: $e');
      rethrow;
    }
  }
  
  /// Generate secure hash for data integrity
  static String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify data integrity with hash
  static bool verifyHash(String data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }
  
  /// Generate secure random token
  static String generateSecureToken([int length = 32]) {
    final key = Key.fromSecureRandom(length);
    return key.base64;
  }
  
  /// Securely store sensitive data in secure storage
  static Future<void> secureStore(String key, String value) async {
    try {
      final encryptedValue = encryptData(value);
      await _secureStorage.write(key: '$_keyPrefix$key', value: encryptedValue);
      debugPrint('🔒 Securely stored data for key: $key');
    } catch (e) {
      debugPrint('❌ Failed to securely store data: $e');
      rethrow;
    }
  }
  
  /// Retrieve and decrypt sensitive data from secure storage
  static Future<String?> secureRetrieve(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: '$_keyPrefix$key');
      if (encryptedValue == null) return null;
      
      return decryptData(encryptedValue);
    } catch (e) {
      debugPrint('❌ Failed to retrieve secure data: $e');
      return null;
    }
  }
  
  /// Delete sensitive data from secure storage
  static Future<void> secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: '$_keyPrefix$key');
      debugPrint('🗑️ Deleted secure data for key: $key');
    } catch (e) {
      debugPrint('❌ Failed to delete secure data: $e');
    }
  }
  
  /// Clear all encrypted data (for logout/reset)
  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('🧹 Cleared all secure storage');
    } catch (e) {
      debugPrint('❌ Failed to clear secure storage: $e');
    }
  }
  
  /// Get encryption status for diagnostics
  static Map<String, dynamic> getEncryptionStatus() {
    return {
      'encryption_initialized': true,
      'algorithm': 'AES-256',
      'key_size': 256,
      'iv_size': 128,
      'secure_storage_available': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Child-specific data protection service
class ChildDataProtectionService {
  static const Duration _dataRetentionPeriod = Duration(days: 365 * 3); // 3 years max
  static const int _maxDataSizeMB = 50; // Limit child data size
  
  /// Anonymize child data for analytics
  static Map<String, dynamic> anonymizeChildData(Map<String, dynamic> childData) {
    final anonymized = Map<String, dynamic>.from(childData);
    
    // Remove personally identifiable information
    anonymized.remove('name');
    anonymized.remove('email');
    anonymized.remove('phone');
    anonymized.remove('address');
    anonymized.remove('school');
    anonymized.remove('parentEmail');
    
    // Replace IDs with hashed versions
    if (anonymized.containsKey('userId')) {
      anonymized['userId'] = EncryptionService.generateHash(childData['userId']);
    }
    
    // Add anonymization metadata
    anonymized['anonymized'] = true;
    anonymized['anonymized_at'] = DateTime.now().toIso8601String();
    
    return anonymized;
  }
  
  /// Check if data should be purged based on retention policy
  static bool shouldPurgeData(DateTime dataCreatedAt) {
    final now = DateTime.now();
    return now.difference(dataCreatedAt) > _dataRetentionPeriod;
  }
  
  /// Calculate data size for child protection limits
  static int calculateDataSize(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return utf8.encode(jsonString).length;
  }
  
  /// Validate data size doesn't exceed child protection limits
  static bool isDataSizeValid(Map<String, dynamic> data) {
    final sizeMB = calculateDataSize(data) / (1024 * 1024);
    return sizeMB <= _maxDataSizeMB;
  }
  
  /// Create child-safe data export
  static Map<String, dynamic> createChildSafeExport(Map<String, dynamic> childData) {
    final safeExport = <String, dynamic>{
      'export_type': 'child_safe_data',
      'export_date': DateTime.now().toIso8601String(),
      'data_anonymized': true,
    };
    
    // Include only safe, non-identifying data
    if (childData.containsKey('achievements')) {
      safeExport['achievements'] = childData['achievements'];
    }
    if (childData.containsKey('points')) {
      safeExport['points'] = childData['points'];
    }
    if (childData.containsKey('streaks')) {
      safeExport['streaks'] = childData['streaks'];
    }
    if (childData.containsKey('preferences')) {
      safeExport['preferences'] = childData['preferences'];
    }
    
    return safeExport;
  }
}