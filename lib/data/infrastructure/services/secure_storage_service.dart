import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for securely storing and retrieving sensitive data like API keys.
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  // Private key for the Google AI API key
  static const String _googleApiKey = 'google_ai_api_key';

  SecureStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Save the Google AI API key securely.
  Future<void> saveGoogleApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _googleApiKey, value: apiKey);
      debugPrint('🔑 SecureStorageService: Google AI API key saved securely.');
    } catch (e) {
      debugPrint('❌ SecureStorageService: Error saving API key: $e');
      // In a real app, you might want to log this to a monitoring service
    }
  }

  /// Retrieve the Google AI API key.
  /// Returns null if the key is not found.
  Future<String?> getGoogleApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _googleApiKey);
      if (apiKey == null) {
        debugPrint('⚠️ SecureStorageService: Google AI API key not found.');
      }
      return apiKey;
    } catch (e) {
      debugPrint('❌ SecureStorageService: Error retrieving API key: $e');
      return null;
    }
  }

  /// Delete the Google AI API key.
  Future<void> deleteGoogleApiKey() async {
    try {
      await _secureStorage.delete(key: _googleApiKey);
      debugPrint('🗑️ SecureStorageService: Google AI API key deleted.');
    } catch (e) {
      debugPrint('❌ SecureStorageService: Error deleting API key: $e');
    }
  }
}
