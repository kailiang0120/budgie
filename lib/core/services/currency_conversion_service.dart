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
    // Add more default rates as needed
  };

  // Cache for exchange rates
  final Map<String, Map<String, double>> _cachedRates = {};
  DateTime _lastFetchTime = DateTime(2000); // Initial time in the past

  // Special map to track rates used for conversions to ensure consistency
  final Map<String, Map<String, double>> _usedRates = {};

  // API endpoints
  static const String _exchangeRateApiUrl =
      'https://open.er-api.com/v6/latest/';

  /// Get the latest exchange rates from an API or Firestore
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      // Check if we have cached rates that are less than 6 hours old
      final now = DateTime.now();
      if (_cachedRates.containsKey(baseCurrency) &&
          now.difference(_lastFetchTime).inHours < 6) {
        debugPrint('🔄 Using cached rates for $baseCurrency');
        return _cachedRates[baseCurrency]!;
      }

      // Check if we have locally stored rates from SharedPreferences
      final localRates = await _getStoredRates(baseCurrency);
      if (localRates != null) {
        // Update in-memory cache
        if (!_cachedRates.containsKey(baseCurrency)) {
          _cachedRates[baseCurrency] = {};
        }
        _cachedRates[baseCurrency] = localRates;
        _lastFetchTime = now;

        // Try to fetch newer rates in the background if we're online
        _fetchFreshRatesInBackground(baseCurrency);

        debugPrint('🔄 Using locally stored rates for $baseCurrency');
        return localRates;
      }

      // Check network connectivity
      bool isConnected = false;
      if (_connectivityService != null) {
        isConnected = await _connectivityService!.isConnected;
      }

      if (isConnected) {
        // Try to get rates from Firestore first (shared across app users)
        final firestoreRates =
            await _getExchangeRatesFromFirestore(baseCurrency);
        if (firestoreRates != null) {
          // Cache the rates
          if (!_cachedRates.containsKey(baseCurrency)) {
            _cachedRates[baseCurrency] = {};
          }
          _cachedRates[baseCurrency] = firestoreRates;
          _lastFetchTime = now;

          // Also save locally
          _storeRatesLocally(baseCurrency, firestoreRates);

          debugPrint('🔄 Using Firestore rates for $baseCurrency');
          return firestoreRates;
        }

        // If not in Firestore, try to fetch from API
        final apiRates = await _fetchExchangeRatesFromApi(baseCurrency);
        if (apiRates != null) {
          // Cache the rates
          if (!_cachedRates.containsKey(baseCurrency)) {
            _cachedRates[baseCurrency] = {};
          }
          _cachedRates[baseCurrency] = apiRates;
          _lastFetchTime = now;

          // Store in Firestore for other users
          _saveExchangeRatesToFirestore(baseCurrency, apiRates);

          // Also save locally
          _storeRatesLocally(baseCurrency, apiRates);

          debugPrint('🔄 Using API rates for $baseCurrency');
          return apiRates;
        }
      }

      // If all else fails, use default rates
      if (_defaultRates.containsKey(baseCurrency)) {
        // Also save locally for future use
        _storeRatesLocally(baseCurrency, _defaultRates[baseCurrency]!);

        debugPrint('🔄 Using default rates for $baseCurrency');
        return _defaultRates[baseCurrency]!;
      }

      // If no default rates for this currency, return empty map
      return {};
    } catch (e) {
      debugPrint('🔄 Error getting exchange rates: $e');
      // Fallback to default rates
      if (_defaultRates.containsKey(baseCurrency)) {
        return _defaultRates[baseCurrency]!;
      }
      return {};
    }
  }

  /// Fetch fresh rates in the background without blocking UI
  Future<void> _fetchFreshRatesInBackground(String baseCurrency) async {
    try {
      // Check connectivity
      bool isConnected = false;
      if (_connectivityService != null) {
        isConnected = await _connectivityService!.isConnected;
      }

      if (!isConnected) return;

      debugPrint('🔄 Fetching fresh rates in background for $baseCurrency');

      // Try API first
      final apiRates = await _fetchExchangeRatesFromApi(baseCurrency);
      if (apiRates != null) {
        // Update in-memory cache
        if (!_cachedRates.containsKey(baseCurrency)) {
          _cachedRates[baseCurrency] = {};
        }
        _cachedRates[baseCurrency] = apiRates;
        _lastFetchTime = DateTime.now();

        // Store in Firestore and locally
        _saveExchangeRatesToFirestore(baseCurrency, apiRates);
        _storeRatesLocally(baseCurrency, apiRates);

        debugPrint('🔄 Updated rates in background for $baseCurrency');
      }
    } catch (e) {
      debugPrint('🔄 Error updating rates in background: $e');
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
      debugPrint('🔄 Stored rates locally for $baseCurrency');
    } catch (e) {
      debugPrint('🔄 Error storing rates locally: $e');
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
      if (DateTime.now().difference(timestamp).inHours < 24) {
        final ratesMap = ratesData['rates'] as Map<String, dynamic>;
        return ratesMap
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      return null;
    } catch (e) {
      debugPrint('🔄 Error getting stored rates: $e');
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
      debugPrint('🔄 Error fetching exchange rates from API: $e');
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
          if (DateTime.now().difference(updateTime).inHours < 24) {
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
      debugPrint('🔄 Error getting exchange rates from Firestore: $e');
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
      debugPrint('🔄 Error saving exchange rates to Firestore: $e');
    }
  }

  /// Get the exchange rate between two currencies
  /// Returns the direct conversion rate or null if not available
  Future<double?> getExchangeRate(
      String fromCurrency, String toCurrency) async {
    // Check if we already have a saved rate for consistency
    if (_usedRates.containsKey(fromCurrency) &&
        _usedRates[fromCurrency]!.containsKey(toCurrency)) {
      return _usedRates[fromCurrency]![toCurrency];
    }

    try {
      // If currencies are the same, rate is 1
      if (fromCurrency == toCurrency) {
        return 1.0;
      }

      // Get exchange rates for the base currency
      final rates = await getExchangeRates(fromCurrency);

      // If we have a direct conversion rate
      if (rates.containsKey(toCurrency)) {
        final rate = rates[toCurrency]!;

        // Save the rate for future consistency
        if (!_usedRates.containsKey(fromCurrency)) {
          _usedRates[fromCurrency] = {};
        }
        _usedRates[fromCurrency]![toCurrency] = rate;

        // Also save the inverse rate for consistency
        if (!_usedRates.containsKey(toCurrency)) {
          _usedRates[toCurrency] = {};
        }
        _usedRates[toCurrency]![fromCurrency] = 1.0 / rate;

        return rate;
      }

      // If no direct rate, return null
      return null;
    } catch (e) {
      debugPrint('🔄 Error getting exchange rate: $e');
      return null;
    }
  }

  /// Convert amount from one currency to another with improved consistency
  Future<double> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    // If currencies are the same, no conversion needed
    if (fromCurrency == toCurrency) {
      return double.parse(amount.toStringAsFixed(2));
    }

    try {
      // First check if we already have a saved rate for consistency
      double? savedRate;
      if (_usedRates.containsKey(fromCurrency) &&
          _usedRates[fromCurrency]!.containsKey(toCurrency)) {
        savedRate = _usedRates[fromCurrency]![toCurrency];
        debugPrint(
            '🔄 Using saved rate for consistency: $savedRate ($fromCurrency to $toCurrency)');
        // Make sure to handle null case even though it's unlikely
        if (savedRate != null) {
          return double.parse((amount * savedRate).toStringAsFixed(2));
        }
      }

      // Get exchange rates for the base currency
      final rates = await getExchangeRates(fromCurrency);

      // If we have a direct conversion rate
      if (rates.containsKey(toCurrency)) {
        final rate = rates[toCurrency]!;

        // Save the rate for future consistency
        if (!_usedRates.containsKey(fromCurrency)) {
          _usedRates[fromCurrency] = {};
        }
        _usedRates[fromCurrency]![toCurrency] = rate;

        // Also save the inverse rate for consistency
        if (!_usedRates.containsKey(toCurrency)) {
          _usedRates[toCurrency] = {};
        }
        _usedRates[toCurrency]![fromCurrency] = 1.0 / rate;

        final convertedAmount = amount * rate;
        return double.parse(convertedAmount.toStringAsFixed(2));
      }

      // If still no conversion path found, use default rates
      if (_defaultRates.containsKey(fromCurrency) &&
          _defaultRates[fromCurrency]!.containsKey(toCurrency)) {
        final rate = _defaultRates[fromCurrency]![toCurrency]!;

        // Save the rate for future consistency
        if (!_usedRates.containsKey(fromCurrency)) {
          _usedRates[fromCurrency] = {};
        }
        _usedRates[fromCurrency]![toCurrency] = rate;

        // Also save the inverse rate for consistency
        if (!_usedRates.containsKey(toCurrency)) {
          _usedRates[toCurrency] = {};
        }
        _usedRates[toCurrency]![fromCurrency] = 1.0 / rate;

        final convertedAmount = amount * rate;
        return double.parse(convertedAmount.toStringAsFixed(2));
      }

      // If all else fails, return the original amount with 2 decimal places
      debugPrint(
          '🔄 No conversion rate found for $fromCurrency to $toCurrency');
      return double.parse(amount.toStringAsFixed(2));
    } catch (e) {
      debugPrint('🔄 Error converting currency: $e');
      return double.parse(amount.toStringAsFixed(2));
    }
  }

  /// Convert amount back using the saved exchange rate for consistency
  Future<double> convertBack(
      double amount, String fromCurrency, String toCurrency) async {
    // If currencies are the same, no conversion needed
    if (fromCurrency == toCurrency) {
      return double.parse(amount.toStringAsFixed(2));
    }

    try {
      // Check if we have the saved rate in the opposite direction
      if (_usedRates.containsKey(toCurrency) &&
          _usedRates[toCurrency]!.containsKey(fromCurrency)) {
        final rate = _usedRates[toCurrency]![fromCurrency]!;
        debugPrint(
            '🔄 Converting back with saved rate: $rate ($fromCurrency to $toCurrency)');
        return double.parse((amount * rate).toStringAsFixed(2));
      }

      // If not, we need to check the forward rate and use its inverse
      if (_usedRates.containsKey(fromCurrency) &&
          _usedRates[fromCurrency]!.containsKey(toCurrency)) {
        final forwardRate = _usedRates[fromCurrency]![toCurrency]!;
        final inverseRate = 1.0 / forwardRate;

        // Save the inverse rate for future consistency
        if (!_usedRates.containsKey(toCurrency)) {
          _usedRates[toCurrency] = {};
        }
        _usedRates[toCurrency]![fromCurrency] = inverseRate;

        debugPrint(
            '🔄 Converting back with calculated inverse rate: $inverseRate');
        return double.parse((amount * inverseRate).toStringAsFixed(2));
      }

      // If we don't have a saved rate in either direction, fetch a new one
      final exchangeRate = await getExchangeRate(toCurrency, fromCurrency);
      if (exchangeRate != null) {
        final convertedAmount = amount * exchangeRate;
        return double.parse(convertedAmount.toStringAsFixed(2));
      }

      // Fall back to regular conversion if no inverse found
      return await convertCurrency(amount, toCurrency, fromCurrency);
    } catch (e) {
      debugPrint('🔄 Error converting currency back: $e');
      return double.parse(amount.toStringAsFixed(2));
    }
  }

  /// Clear saved rates to force fresh conversion rates
  void clearSavedRates() {
    _usedRates.clear();
    debugPrint('🔄 Cleared saved conversion rates');
  }
}
