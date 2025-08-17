import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/connectivity_service.dart';
import 'package:flutter/material.dart';

/// Service for handling currency conversion with exchange rates from Bank Negara Malaysia (BNM)
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

  // BNM API configuration
  static const String _bnmApiBaseUrl = 'https://api.bnm.gov.my/public';
  static const String _exchangeRateEndpoint = '/exchange-rate';
  static const Map<String, String> _bnmHeaders = {
    'Accept': 'application/vnd.BNM.API.v1+json',
    'Content-Type': 'application/json',
  };

  // Cache configuration
  static const String _cacheKeyPrefix = 'bnm_exchange_rates_';
  static const String _lastUpdateKey = 'bnm_last_update';
  static const int _cacheExpirationHours = 6;

  // Cache for exchange rates
  final Map<String, Map<String, double>> _memoryCache = {};
  DateTime _lastMemoryCacheUpdate = DateTime(2000);

  // Supported currencies by BNM (only the ones requested by user)
  static const List<String> _supportedCurrencies = [
    'USD',
    'EUR',
    'SGD',
    'CNY',
    'AUD',
    'IDR',
  ];

  // Default fallback rates (approximate, for emergency use only)
  // Updated rates as of recent data (1 MYR = X foreign currency)
  final Map<String, double> _defaultRates = {
    'USD': 0.22, // 1 MYR ≈ 0.22 USD
    'EUR': 0.21, // 1 MYR ≈ 0.21 EUR
    'SGD': 0.30, // 1 MYR ≈ 0.30 SGD
    'CNY': 1.60, // 1 MYR ≈ 1.60 CNY
    'AUD': 0.35, // 1 MYR ≈ 0.35 AUD
    'IDR': 3500, // 1 MYR ≈ 3500 IDR
  };

  /// Get exchange rates for MYR to other currencies
  Future<Map<String, double>> getExchangeRates() async {
    try {
      // 1. Check memory cache first
      if (_isMemoryCacheValid()) {
        if (kDebugMode) {
          debugPrint('Using memory cache for exchange rates');
        }
        return _memoryCache['MYR'] ?? {};
      }

      // 2. Check if connected to internet
      final isConnected = await _isNetworkConnected();
      if (kDebugMode) {
        debugPrint('Network connection status: $isConnected');
      }

      if (isConnected) {
        // 3. Try to fetch from BNM API
        if (kDebugMode) {
          debugPrint('Attempting to fetch exchange rates from BNM API');
        }
        final apiRates = await _fetchFromBnmApi();
        if (apiRates != null && apiRates.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
                'Successfully fetched ${apiRates.length} rates from BNM API: $apiRates');
          }
          // Cache the fresh data
          await _cacheRates(apiRates);
          _updateMemoryCache(apiRates);
          return apiRates;
        } else {
          if (kDebugMode) {
            debugPrint(
                'Failed to fetch rates from BNM API or received empty response');
          }
        }
      }

      // 4. Try to get from local storage
      if (kDebugMode) {
        debugPrint('Attempting to get cached exchange rates');
      }
      final cachedRates = await _getCachedRates();
      if (cachedRates != null && cachedRates.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('Using cached exchange rates: $cachedRates');
        }
        _updateMemoryCache(cachedRates);

        // Notify user they're using cached data if offline
        if (!isConnected) {
          // UI should handle offline notification
          return {};
        }

        return cachedRates;
      }

      // 5. If all else fails and we're offline, notify user
      if (!isConnected) {
        if (kDebugMode) {
          debugPrint('No cached data available and device is offline');
        }
        // UI should handle offline notification
        return {};
      }

      // 6. Last resort: return empty map
      if (kDebugMode) {
        debugPrint('No exchange rates available from any source');
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting exchange rates: $e');
      }

      // Try cached rates on error
      final cachedRates = await _getCachedRates();
      if (cachedRates != null) {
        if (kDebugMode) {
          debugPrint('Using cached rates after error: $cachedRates');
        }
        return cachedRates;
      }

      if (kDebugMode) {
        debugPrint('No fallback data available');
      }
      return {};
    }
  }

  /// Fetch exchange rates from BNM API
  Future<Map<String, double>?> _fetchFromBnmApi() async {
    try {
      // BNM API provides rates with MYR as base currency
      final uri = Uri.parse('$_bnmApiBaseUrl$_exchangeRateEndpoint');

      final response = await http
          .get(uri, headers: _bnmHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'] is List) {
          final rates = <String, double>{};

          for (final item in data['data']) {
            if (item['currency_code'] != null && item['rate'] != null) {
              final currency = item['currency_code'] as String;
              final unit = item['unit'] as int? ?? 1;
              final rateData = item['rate'] as Map<String, dynamic>;
              final middleRate = _parseRate(rateData['middle_rate']);

              if (middleRate != null &&
                  _supportedCurrencies.contains(currency)) {
                // BNM gives rates as: unit of foreign currency = middleRate MYR
                // We need: 1 MYR = X foreign currency
                // So: 1 MYR = unit / middleRate foreign currency
                final convertedRate = unit / middleRate;
                rates[currency] = convertedRate;
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
                'Successfully fetched ${rates.length} exchange rates from BNM API');
          }
          return rates;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'BNM API error: ${response.statusCode} - ${response.body}');
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching from BNM API: $e');
      }
      return null;
    }
  }

  /// Parse rate value from API response
  double? _parseRate(dynamic rateValue) {
    if (rateValue == null) return null;

    if (rateValue is num) {
      return rateValue.toDouble();
    }

    if (rateValue is String) {
      return double.tryParse(rateValue);
    }

    return null;
  }

  /// Check if device is connected to network
  Future<bool> _isNetworkConnected() async {
    if (_connectivityService == null) return false;
    return await _connectivityService!.isConnected;
  }

  /// Check if memory cache is still valid
  bool _isMemoryCacheValid() {
    if (_memoryCache.isEmpty) return false;

    final now = DateTime.now();
    final timeSinceUpdate = now.difference(_lastMemoryCacheUpdate);

    return timeSinceUpdate.inHours < _cacheExpirationHours;
  }

  /// Update memory cache
  void _updateMemoryCache(Map<String, double> rates) {
    _memoryCache['MYR'] = rates;
    _lastMemoryCacheUpdate = DateTime.now();
  }

  /// Cache rates to local storage
  Future<void> _cacheRates(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'rates': rates,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString('${_cacheKeyPrefix}MYR', json.encode(cacheData));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        debugPrint('Exchange rates cached successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error caching rates: $e');
      }
    }
  }

  /// Get cached rates from local storage
  Future<Map<String, double>?> _getCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('${_cacheKeyPrefix}MYR');

      if (cacheString == null) return null;

      final cacheData = json.decode(cacheString) as Map<String, dynamic>;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp'] as int);

      // Check if cache is not too old (extend to 7 days for offline use)
      final now = DateTime.now();
      if (now.difference(timestamp).inDays > 7) {
        return null;
      }

      final ratesMap = cacheData['rates'] as Map<String, dynamic>;
      return ratesMap
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cached rates: $e');
      }
      return null;
    }
  }

  /// Get exchange rate between two currencies
  Future<double?> getExchangeRate(
      String fromCurrency, String toCurrency) async {
    if (kDebugMode) {
      debugPrint('💱 Getting exchange rate: $fromCurrency -> $toCurrency');
    }

    if (fromCurrency == toCurrency) return 1.0;

    try {
      final rates = await getExchangeRates();
      if (kDebugMode) {
        debugPrint('💱 Available exchange rates: $rates');
      }

      if (fromCurrency == 'MYR') {
        // Converting from MYR to other currency
        final rate = rates[toCurrency];
        if (kDebugMode) {
          debugPrint('💱 MYR to $toCurrency rate: $rate');
        }
        return rate;
      } else if (toCurrency == 'MYR') {
        // Converting from other currency to MYR
        final rate = rates[fromCurrency];
        if (rate != null && rate > 0) {
          final myrRate = 1.0 / rate;
          if (kDebugMode) {
            debugPrint(
                '💱 $fromCurrency to MYR rate: $myrRate (inverse of $rate)');
          }
          return myrRate;
        } else {
          if (kDebugMode) {
            debugPrint('💱 Invalid rate for $fromCurrency: $rate');
          }
          return null;
        }
      } else {
        // Converting between two non-MYR currencies
        final fromRate = rates[fromCurrency];
        final toRate = rates[toCurrency];
        if (kDebugMode) {
          debugPrint(
              '💱 Cross conversion: $fromCurrency rate: $fromRate, $toCurrency rate: $toRate');
        }

        if (fromRate != null && toRate != null && fromRate > 0) {
          // Convert via MYR: fromCurrency -> MYR -> toCurrency
          final crossRate = toRate / fromRate;
          if (kDebugMode) {
            debugPrint('💱 Cross rate calculated: $crossRate');
          }
          return crossRate;
        }
      }

      if (kDebugMode) {
        debugPrint(
            '💱 No exchange rate found for $fromCurrency -> $toCurrency');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '💱 Error getting exchange rate from $fromCurrency to $toCurrency: $e');
      }
      return null;
    }
  }

  /// Convert amount from one currency to another
  Future<double> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    if (kDebugMode) {
      debugPrint('💱 Converting $amount from $fromCurrency to $toCurrency');
    }

    if (fromCurrency == toCurrency) {
      if (kDebugMode) {
        debugPrint('💱 Same currency, returning original amount: $amount');
      }
      return _formatAmount(amount);
    }

    try {
      final rate = await getExchangeRate(fromCurrency, toCurrency);
      if (kDebugMode) {
        debugPrint('💱 Exchange rate from $fromCurrency to $toCurrency: $rate');
      }

      if (rate != null && rate > 0) {
        final convertedAmount = _formatAmount(amount * rate);
        if (kDebugMode) {
          debugPrint(
              '💱 Converted $amount $fromCurrency to $convertedAmount $toCurrency (rate: $rate)');
        }
        return convertedAmount;
      }

      // Enhanced fallback logic for different conversion scenarios
      double? fallbackRate;

      if (fromCurrency == 'MYR' && _defaultRates.containsKey(toCurrency)) {
        fallbackRate = _defaultRates[toCurrency]!;
        if (kDebugMode) {
          debugPrint(
              '💱 Using fallback rate MYR to $toCurrency: $fallbackRate');
        }
      } else if (toCurrency == 'MYR' &&
          _defaultRates.containsKey(fromCurrency)) {
        fallbackRate = 1.0 / _defaultRates[fromCurrency]!;
        if (kDebugMode) {
          debugPrint(
              '💱 Using fallback rate $fromCurrency to MYR: $fallbackRate (inverse of ${_defaultRates[fromCurrency]})');
        }
      } else if (_defaultRates.containsKey(fromCurrency) &&
          _defaultRates.containsKey(toCurrency)) {
        // Cross conversion using MYR as intermediate
        final fromToMyrRate = 1.0 / _defaultRates[fromCurrency]!;
        final myrToToRate = _defaultRates[toCurrency]!;
        fallbackRate = fromToMyrRate * myrToToRate;
        if (kDebugMode) {
          debugPrint(
              '💱 Using fallback cross rate $fromCurrency to $toCurrency: $fallbackRate');
        }
      }

      if (fallbackRate != null && fallbackRate > 0) {
        final convertedAmount = _formatAmount(amount * fallbackRate);
        if (kDebugMode) {
          debugPrint(
              '💱 Converted using fallback: $amount $fromCurrency to $convertedAmount $toCurrency');
        }
        return convertedAmount;
      }

      // If no rate available, return original amount
      if (kDebugMode) {
        debugPrint(
            '💱 No conversion rate available from $fromCurrency to $toCurrency, returning original amount');
      }
      return _formatAmount(amount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💱 Error converting currency: $e');
      }
      return _formatAmount(amount);
    }
  }

  /// Format amount to 2 decimal places
  double _formatAmount(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }

  /// Force refresh exchange rates from API
  /// Accepts an optional BuildContext and callbacks for UI feedback
  Future<bool> refreshRates({
    BuildContext? context,
    void Function(String message,
            {bool isError, bool isLoading, bool isSuccess})?
        onStatus,
  }) async {
    try {
      final isConnected = await _isNetworkConnected();
      if (!isConnected) {
        if (onStatus != null) {
          onStatus('Cannot refresh rates while offline', isError: true);
        }
        return false;
      }
      if (onStatus != null) {
        onStatus('Updating exchange rates...', isLoading: true);
      }
      final apiRates = await _fetchFromBnmApi();
      if (apiRates != null && apiRates.isNotEmpty) {
        await _cacheRates(apiRates);
        _updateMemoryCache(apiRates);
        if (onStatus != null) {
          onStatus('Back online! Exchange rates updated', isSuccess: true);
        }
        return true;
      }
      if (onStatus != null) {
        onStatus('Failed to refresh exchange rates', isError: true);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing rates: $e');
      }
      if (onStatus != null) {
        onStatus('Error refreshing rates: $e', isError: true);
      }
      return false;
    }
  }

  /// Get the last update time
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateKey);

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting last update time: $e');
      }
      return null;
    }
  }

  /// Get supported currencies
  List<String> getSupportedCurrencies() {
    return List.from(_supportedCurrencies);
  }

  /// Check if rates are stale (older than cache expiration)
  Future<bool> areRatesStale() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    return now.difference(lastUpdate).inHours >= _cacheExpirationHours;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}MYR');
      await prefs.remove(_lastUpdateKey);

      _memoryCache.clear();
      _lastMemoryCacheUpdate = DateTime(2000);

      if (kDebugMode) {
        debugPrint('Exchange rate cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing cache: $e');
      }
    }
  }
}
