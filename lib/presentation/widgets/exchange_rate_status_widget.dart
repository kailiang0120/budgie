import 'package:flutter/material.dart';
import '../../data/infrastructure/services/currency_conversion_service.dart';
import '../../data/infrastructure/services/offline_notification_service.dart';
import '../../di/injection_container.dart' as di;

/// Widget to display exchange rate status and allow manual refresh
class ExchangeRateStatusWidget extends StatefulWidget {
  const ExchangeRateStatusWidget({Key? key}) : super(key: key);

  @override
  State<ExchangeRateStatusWidget> createState() =>
      _ExchangeRateStatusWidgetState();
}

class _ExchangeRateStatusWidgetState extends State<ExchangeRateStatusWidget> {
  DateTime? _lastUpdateTime;
  bool _isLoading = false;
  bool _isStale = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final currencyService = di.sl<CurrencyConversionService>();
      final lastUpdate = await currencyService.getLastUpdateTime();
      final isStale = await currencyService.areRatesStale();

      if (mounted) {
        setState(() {
          _lastUpdateTime = lastUpdate;
          _isStale = isStale;
        });
      }
    } catch (e) {
      debugPrint('Error checking exchange rate status: $e');
    }
  }

  Future<void> _refreshRates() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currencyService = di.sl<CurrencyConversionService>();
      final success = await currencyService.refreshRates();

      if (success) {
        await _checkStatus();
      }
    } catch (e) {
      debugPrint('Error refreshing rates: $e');
      final notificationService = di.sl<OfflineNotificationService>();
      notificationService
          .showErrorNotification('Failed to refresh exchange rates');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusText() {
    if (_lastUpdateTime == null) {
      return 'Exchange rates not loaded';
    }

    final now = DateTime.now();
    final difference = now.difference(_lastUpdateTime!);

    if (difference.inDays > 0) {
      return 'Updated ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Updated ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Updated ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Updated just now';
    }
  }

  Color _getStatusColor() {
    if (_lastUpdateTime == null) {
      return Colors.red;
    }

    if (_isStale) {
      return Colors.orange;
    }

    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (_lastUpdateTime == null) {
      return Icons.error_outline;
    }

    if (_isStale) {
      return Icons.schedule;
    }

    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isStale || _lastUpdateTime == null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isLoading ? null : _refreshRates,
              child: _isLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      size: 16,
                      color: _getStatusColor(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version for smaller spaces
class CompactExchangeRateStatusWidget extends StatefulWidget {
  const CompactExchangeRateStatusWidget({Key? key}) : super(key: key);

  @override
  State<CompactExchangeRateStatusWidget> createState() =>
      _CompactExchangeRateStatusWidgetState();
}

class _CompactExchangeRateStatusWidgetState
    extends State<CompactExchangeRateStatusWidget> {
  bool _isStale = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final currencyService = di.sl<CurrencyConversionService>();
      final isStale = await currencyService.areRatesStale();

      if (mounted) {
        setState(() {
          _isStale = isStale;
        });
      }
    } catch (e) {
      debugPrint('Error checking exchange rate status: $e');
    }
  }

  Future<void> _refreshRates() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currencyService = di.sl<CurrencyConversionService>();
      await currencyService.refreshRates();
      await _checkStatus();
    } catch (e) {
      debugPrint('Error refreshing rates: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStale && !_isLoading) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _isLoading ? null : _refreshRates,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : const Icon(
                Icons.refresh,
                size: 12,
                color: Colors.orange,
              ),
      ),
    );
  }
}
