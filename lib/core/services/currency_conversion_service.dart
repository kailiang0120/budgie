import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/connectivity_service.dart';

/// Service for handling currency conversion with exchange rates
class CurrencyConversionService {
  // Singleton instance
  static final CurrencyConversionService _instance =
      CurrencyConversionService._internal();
  factory CurrencyConversionService() => _instance;
  CurrencyConversionService._internal();

  // Dependencies
  ConnectivityService? _connectivityService;

  // Set dependencies (called from injection container)
  void setConnectivityService(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
  }

  // Default exchange rates (fallback if API fails)
  final Map<String, Map<String, double>> _defaultRates = {
    'MYR': {
      'USD': 0.21,
      'EUR': 0.20,
      'GBP': 0.17,
      'SGD': 0.29,
      'JPY': 32.58,
      'CNY': 1.52,
      'THB': 7.57,
      'INR': 17.64,
      'AUD': 0.32,
      'CAD': 0.29,
      'HKD': 1.65,
      'KRW': 288.72,
      'CHF': 0.19,
      'NZD': 0.35,
      'PHP': 12.18,
      'VND': 5347.50,
      'IDR': 3372.66
    },
    'USD': {
      'MYR': 4.73,
      'EUR': 0.93,
      'GBP': 0.79,
      'SGD': 1.36,
      'JPY': 154.19,
      'CNY': 7.20,
      'THB': 35.81,
      'INR': 83.42,
      'AUD': 1.53,
      'CAD': 1.37,
      'HKD': 7.82,
      'KRW': 1365.73,
      'CHF': 0.91,
      'NZD': 1.64,
      'PHP': 57.61,
      'VND': 25292.50,
      'IDR': 15950.35
    },
    'EUR': {
      'MYR': 5.08,
      'USD': 1.07,
      'GBP': 0.85,
      'SGD': 1.46,
      'JPY': 165.57,
      'CNY': 7.73,
      'THB': 38.44,
      'INR': 89.50,
      'AUD': 1.64,
      'CAD': 1.47,
      'HKD': 8.39,
      'KRW': 1466.03,
      'CHF': 0.97,
      'NZD': 1.76,
      'PHP': 61.84,
      'VND': 27153.50,
      'IDR': 17123.98
    },
  };

  // Cache for exchange rates
  final Map<String, Map<String, double>> _cachedRates = {};
  DateTime _lastFetchTime = DateTime(2000); // Initial time in the past

  // Special map to track rates used for conversions to ensure consistency
  final Map<String, Map<String, double>> _usedRates = {};

  // API endpoints
  static const String _exchangeRateApiUrl =
      'https://open.er-api.com/v6/latest/';

  /// Constants for cache expiration
  static const int _cacheExpirationHours = 6;
  static const int _localStorageExpirationHours = 24;

  /// Get the latest exchange rates from an API or Firestore
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      // 1. Check in-memory cache first (fastest)
      final inMemoryRates = _getFromMemoryCache(baseCurrency);
      if (inMemoryRates != null) return inMemoryRates;

      // 2. Try local storage next
      final localRates = await _getStoredRates(baseCurrency);
      if (localRates != null) {
        _updateCachedRates(baseCurrency, localRates);
        _fetchFreshRatesInBackground(baseCurrency);
        return localRates;
      }

      // 3. Try network sources if connected
      final isConnected = await _isNetworkConnected();
      if (isConnected) {
        // Try Firestore first (shared across app users)
        final firestoreRates =
            await _getExchangeRatesFromFirestore(baseCurrency);
        if (firestoreRates != null) {
          _saveRatesToAllCaches(baseCurrency, firestoreRates);
          return firestoreRates;
        }

        // Then try external API
        final apiRates = await _fetchExchangeRatesFromApi(baseCurrency);
        if (apiRates != null) {
          _saveRatesToAllCaches(baseCurrency, apiRates);
          return apiRates;
        }
      }

      // 4. Fall back to default rates
      if (_defaultRates.containsKey(baseCurrency)) {
        final defaultRates = _defaultRates[baseCurrency]!;
        _storeRatesLocally(baseCurrency, defaultRates);
        return defaultRates;
      }

      // Last resort: empty map
      return {};
    } catch (e) {
      debugPrint('Error getting exchange rates: $e');
      // Fallback to default rates
      return _defaultRates[baseCurrency] ?? {};
    }
  }

  /// Check if device is connected to network
  Future<bool> _isNetworkConnected() async {
    if (_connectivityService == null) return false;
    return await _connectivityService!.isConnected;
  }

  /// Get rates from memory cache if not expired
  Map<String, double>? _getFromMemoryCache(String baseCurrency) {
    final now = DateTime.now();
    if (_cachedRates.containsKey(baseCurrency) &&
        now.difference(_lastFetchTime).inHours < _cacheExpirationHours) {
      return _cachedRates[baseCurrency];
    }
    return null;
  }

  /// Update the in-memory cache with new rates
  void _updateCachedRates(String baseCurrency, Map<String, double> rates) {
    _cachedRates[baseCurrency] = rates;
    _lastFetchTime = DateTime.now();
  }

  /// Save rates to all caching mechanisms (memory, local storage, Firestore)
  Future<void> _saveRatesToAllCaches(
      String baseCurrency, Map<String, double> rates) async {
    _updateCachedRates(baseCurrency, rates);
    await _storeRatesLocally(baseCurrency, rates);
    await _saveExchangeRatesToFirestore(baseCurrency, rates);
  }

  /// Fetch fresh rates in the background without blocking UI
  Future<void> _fetchFreshRatesInBackground(String baseCurrency) async {
    try {
      if (!await _isNetworkConnected()) return;

      final apiRates = await _fetchExchangeRatesFromApi(baseCurrency);
      if (apiRates != null) {
        _saveRatesToAllCaches(baseCurrency, apiRates);
      }
    } catch (e) {
      debugPrint('Error updating rates in background: $e');
    }
  }

  /// Store rates locally using SharedPreferences
  Future<void> _storeRatesLocally(
      String baseCurrency, Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesData = {
        'rates': rates,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };

      await prefs.setString(
          'exchange_rates_$baseCurrency', jsonEncode(ratesData));
    } catch (e) {
      debugPrint('Error storing rates locally: $e');
    }
  }

  /// Get rates stored locally
  Future<Map<String, double>?> _getStoredRates(String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesString = prefs.getString('exchange_rates_$baseCurrency');

      if (ratesString == null) return null;

      final ratesData = jsonDecode(ratesString) as Map<String, dynamic>;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(ratesData['timestamp'] as int);

      // Check if rates are less than 24 hours old
      if (DateTime.now().difference(timestamp).inHours <
          _localStorageExpirationHours) {
        final ratesMap = ratesData['rates'] as Map<String, dynamic>;
        return ratesMap
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      return null;
    } catch (e) {
      debugPrint('Error getting stored rates: $e');
      return null;
    }
  }

  /// Fetch exchange rates from an external API
  Future<Map<String, double>?> _fetchExchangeRatesFromApi(
      String baseCurrency) async {
    try {
      final response =
          await http.get(Uri.parse('$_exchangeRateApiUrl$baseCurrency'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null) {
          return Map<String, double>.from(data['rates']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching exchange rates from API: $e');
      return null;
    }
  }

  /// Get exchange rates from Firestore
  Future<Map<String, double>?> _getExchangeRatesFromFirestore(
      String baseCurrency) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('exchange_rates')
          .doc(baseCurrency)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Check if rates are recent (less than 24 hours old)
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final updateTime = timestamp.toDate();
          if (DateTime.now().difference(updateTime).inHours <
              _localStorageExpirationHours) {
            final rates = data['rates'] as Map<String, dynamic>?;
            if (rates != null) {
              return rates.map(
                  (key, value) => MapEntry(key, (value as num).toDouble()));
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting exchange rates from Firestore: $e');
      return null;
    }
  }

  /// Save exchange rates to Firestore for caching
  Future<void> _saveExchangeRatesToFirestore(
      String baseCurrency, Map<String, double> rates) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('exchange_rates')
          .doc(baseCurrency)
          .set({
        'rates': rates,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });
    } catch (e) {
      debugPrint('Error saving exchange rates to Firestore: $e');
    }
  }

  /// Get the exchange rate between two currencies
  /// Returns the direct conversion rate or null if not available
  Future<double?> getExchangeRate(
      String fromCurrency, String toCurrency) async {
    // If currencies are the same, rate is 1
    if (fromCurrency == toCurrency) return 1.0;

    // Check if we already have a saved rate for consistency
    if (_usedRates.containsKey(fromCurrency) &&
        _usedRates[fromCurrency]!.containsKey(toCurrency)) {
      return _usedRates[fromCurrency]![toCurrency];
    }

    try {
      // Get exchange rates for the base currency
      final rates = await getExchangeRates(fromCurrency);

      // If we have a direct conversion rate
      if (rates.containsKey(toCurrency)) {
        final rate = rates[toCurrency]!;
        _saveRateForConsistency(fromCurrency, toCurrency, rate);
        return rate;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting exchange rate: $e');
      return null;
    }
  }

  /// Save rate and its inverse for future consistency
  void _saveRateForConsistency(
      String fromCurrency, String toCurrency, double rate) {
    // Save direct rate
    if (!_usedRates.containsKey(fromCurrency)) {
      _usedRates[fromCurrency] = {};
    }
    _usedRates[fromCurrency]![toCurrency] = rate;

    // Save inverse rate
    if (!_usedRates.containsKey(toCurrency)) {
      _usedRates[toCurrency] = {};
    }
    _usedRates[toCurrency]![fromCurrency] = 1.0 / rate;
  }

  /// Convert amount from one currency to another with improved consistency
  Future<double> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    // If currencies are the same, no conversion needed
    if (fromCurrency == toCurrency) {
      return _formatAmount(amount);
    }

    try {
      // Try using a saved rate first for consistency
      double? savedRate = _getSavedRate(fromCurrency, toCurrency);
      if (savedRate != null) {
        return _formatAmount(amount * savedRate);
      }

      // Get fresh rates and convert
      final rates = await getExchangeRates(fromCurrency);

      // If we have a direct conversion rate
      if (rates.containsKey(toCurrency)) {
        final rate = rates[toCurrency]!;
        _saveRateForConsistency(fromCurrency, toCurrency, rate);
        return _formatAmount(amount * rate);
      }

      // Try default rates as fallback
      if (_defaultRates.containsKey(fromCurrency) &&
          _defaultRates[fromCurrency]!.containsKey(toCurrency)) {
        final rate = _defaultRates[fromCurrency]![toCurrency]!;
        _saveRateForConsistency(fromCurrency, toCurrency, rate);
        return _formatAmount(amount * rate);
      }

      // If all else fails, return the original amount with 2 decimal places
      debugPrint('No conversion rate found for $fromCurrency to $toCurrency');
      return _formatAmount(amount);
    } catch (e) {
      debugPrint('Error converting currency: $e');
      return _formatAmount(amount);
    }
  }

  /// Get saved rate if available
  double? _getSavedRate(String fromCurrency, String toCurrency) {
    if (_usedRates.containsKey(fromCurrency) &&
        _usedRates[fromCurrency]!.containsKey(toCurrency)) {
      return _usedRates[fromCurrency]![toCurrency];
    }
    return null;
  }

  /// Format amount to 2 decimal places
  double _formatAmount(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }

  /// Convert amount back using the saved exchange rate for consistency
  Future<double> convertBack(
      double amount, String fromCurrency, String toCurrency) async {
    // If currencies are the same, no conversion needed
    if (fromCurrency == toCurrency) {
      return _formatAmount(amount);
    }

    try {
      // Check for direct saved rate (toCurrency -> fromCurrency)
      double? directRate = _getSavedRate(toCurrency, fromCurrency);
      if (directRate != null) {
        return _formatAmount(amount * directRate);
      }

      // Check for inverse of saved rate (fromCurrency -> toCurrency)
      double? inverseSourceRate = _getSavedRate(fromCurrency, toCurrency);
      if (inverseSourceRate != null) {
        double inverseRate = 1.0 / inverseSourceRate;
        _saveRateForConsistency(toCurrency, fromCurrency, inverseRate);
        return _formatAmount(amount * inverseRate);
      }

      // Get a fresh rate
      final exchangeRate = await getExchangeRate(toCurrency, fromCurrency);
      if (exchangeRate != null) {
        return _formatAmount(amount * exchangeRate);
      }

      // Fall back to regular conversion if no inverse found
      return await convertCurrency(amount, toCurrency, fromCurrency);
    } catch (e) {
      debugPrint('Error converting currency back: $e');
      return _formatAmount(amount);
    }
  }
}
