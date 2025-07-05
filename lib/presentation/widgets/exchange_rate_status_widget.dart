import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/infrastructure/services/currency_conversion_service.dart';
import '../../di/injection_container.dart' as di;
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

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
      final success = await currencyService.refreshRates(
        context: context,
        onStatus: (message,
            {isError = false, isLoading = false, isSuccess = false}) {
          if (context.mounted && message.isNotEmpty) {
            final color = isError
                ? Colors.red
                : isSuccess
                    ? Colors.green
                    : isLoading
                        ? Colors.indigo
                        : Colors.blue;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: Colors.white,
                    )),
                backgroundColor: color,
                duration: Duration(seconds: isLoading ? 2 : 3),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      );
      if (success) {
        await _checkStatus();
      }
    } catch (e) {
      debugPrint('Error refreshing rates: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh exchange rates',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeSmall.sp,
                  color: Colors.white,
                )),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
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
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMedium.w,
        vertical: AppConstants.spacingSmall.h,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor()
            .withAlpha((255 * AppConstants.opacityOverlay).toInt()),
        border: Border.all(
          color: _getStatusColor()
              .withAlpha((255 * AppConstants.opacityLow).toInt()),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: AppConstants.iconSizeSmall.sp,
            color: _getStatusColor(),
          ),
          SizedBox(width: AppConstants.spacingXSmall.w),
          Flexible(
            child: Text(
              _getStatusText(),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: AppConstants.textSizeSmall.sp,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isStale || _lastUpdateTime == null) ...[
            SizedBox(width: AppConstants.spacingSmall.w),
            GestureDetector(
              onTap: _isLoading ? null : _refreshRates,
              child: _isLoading
                  ? SizedBox(
                      width: AppConstants.iconSizeSmall.w,
                      height: AppConstants.iconSizeSmall.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      size: AppConstants.iconSizeSmall.sp,
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
      final success = await currencyService.refreshRates(
        context: context,
        onStatus: (message,
            {isError = false, isLoading = false, isSuccess = false}) {
          if (context.mounted && message.isNotEmpty) {
            final color = isError
                ? Colors.red
                : isSuccess
                    ? Colors.green
                    : isLoading
                        ? Colors.indigo
                        : Colors.blue;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: Colors.white,
                    )),
                backgroundColor: color,
                duration: Duration(seconds: isLoading ? 2 : 3),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      );
      if (success) {
        await _checkStatus();
      }
    } catch (e) {
      debugPrint('Error refreshing rates: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh exchange rates',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppConstants.textSizeSmall.sp,
                  color: Colors.white,
                )),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
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
    return GestureDetector(
      onTap: _isLoading ? null : _refreshRates,
      child: Container(
        padding: EdgeInsets.all(AppConstants.spacingXSmall.w),
        decoration: BoxDecoration(
          color: _isStale ? Colors.orange : Colors.green,
          shape: BoxShape.circle,
        ),
        child: _isLoading
            ? SizedBox(
                width: AppConstants.iconSizeSmall.w,
                height: AppConstants.iconSizeSmall.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _isStale ? Colors.orange : Colors.green),
                ),
              )
            : Icon(
                _isStale ? Icons.sync_problem : Icons.sync,
                size: AppConstants.iconSizeSmall.sp,
                color: _isStale ? Colors.orange : Colors.green,
              ),
      ),
    );
  }
}
