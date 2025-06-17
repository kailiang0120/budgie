class CurrencyFormatter {
  /// Get currency symbol for the given currency code
  static String getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'MYR':
        return 'RM ';
      case 'USD':
        return '\$ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      case 'JPY':
        return '¥ ';
      case 'CNY':
        return '¥ ';
      case 'SGD':
        return 'S\$ ';
      case 'THB':
        return '฿ ';
      case 'INR':
        return '₹ ';
      case 'KRW':
        return '₩ ';
      case 'AUD':
        return 'A\$ ';
      case 'CAD':
        return 'C\$ ';
      case 'HKD':
        return 'HK\$ ';
      case 'TWD':
        return 'NT\$ ';
      case 'NZD':
        return 'NZ\$ ';
      case 'CHF':
        return 'CHF ';
      case 'SEK':
        return 'kr ';
      case 'NOK':
        return 'kr ';
      case 'DKK':
        return 'kr ';
      case 'PLN':
        return 'zł ';
      case 'CZK':
        return 'Kč ';
      case 'HUF':
        return 'Ft ';
      case 'RUB':
        return '₽ ';
      case 'BRL':
        return 'R\$ ';
      case 'MXN':
        return 'Mex\$ ';
      case 'ARS':
        return 'AR\$ ';
      case 'CLP':
        return 'CL\$ ';
      case 'COP':
        return 'CO\$ ';
      case 'PEN':
        return 'S/ ';
      case 'VND':
        return '₫ ';
      case 'IDR':
        return 'Rp ';
      case 'PHP':
        return '₱ ';
      case 'ZAR':
        return 'R ';
      case 'EGP':
        return 'E£ ';
      case 'NGN':
        return '₦ ';
      case 'KES':
        return 'KSh ';
      case 'GHS':
        return 'GH₵ ';
      case 'MAD':
        return 'DH ';
      case 'TND':
        return 'DT ';
      case 'AED':
        return 'AED ';
      case 'SAR':
        return 'SR ';
      case 'QAR':
        return 'QR ';
      case 'KWD':
        return 'KD ';
      case 'BHD':
        return 'BD ';
      case 'OMR':
        return 'RO ';
      case 'JOD':
        return 'JD ';
      case 'LBP':
        return 'L£ ';
      case 'ILS':
        return '₪ ';
      case 'TRY':
        return '₺ ';
      case 'UAH':
        return '₴ ';
      case 'RON':
        return 'lei ';
      case 'BGN':
        return 'лв ';
      case 'HRK':
        return 'kn ';
      case 'RSD':
        return 'дин ';
      case 'MKD':
        return 'ден ';
      case 'ALL':
        return 'L ';
      case 'BAM':
        return 'KM ';
      default:
        return '$currency ';
    }
  }

  /// Format amount with currency symbol
  static String formatAmount(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format amount with currency symbol for display
  static String formatAmountWithCurrency(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get supported currencies list (BNM supported currencies)
  static List<String> getSupportedCurrencies() {
    return [
      'MYR', // Malaysian Ringgit (base currency)
      'USD', // US Dollar
      'EUR', // Euro
      'SGD', // Singapore Dollar
      'CNY', // Chinese Yuan
      'AUD', // Australian Dollar
      'IDR', // Indonesian Rupiah
    ];
  }

  /// Get currency name for display
  static String getCurrencyName(String currency) {
    switch (currency.toUpperCase()) {
      case 'MYR':
        return 'Malaysian Ringgit';
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'JPY':
        return 'Japanese Yen';
      case 'CNY':
        return 'Chinese Yuan';
      case 'SGD':
        return 'Singapore Dollar';
      case 'THB':
        return 'Thai Baht';
      case 'INR':
        return 'Indian Rupee';
      case 'KRW':
        return 'South Korean Won';
      case 'AUD':
        return 'Australian Dollar';
      case 'CAD':
        return 'Canadian Dollar';
      case 'HKD':
        return 'Hong Kong Dollar';
      case 'TWD':
        return 'Taiwan Dollar';
      case 'NZD':
        return 'New Zealand Dollar';
      case 'CHF':
        return 'Swiss Franc';
      case 'SEK':
        return 'Swedish Krona';
      case 'NOK':
        return 'Norwegian Krone';
      case 'DKK':
        return 'Danish Krone';
      case 'PLN':
        return 'Polish Zloty';
      case 'CZK':
        return 'Czech Koruna';
      case 'HUF':
        return 'Hungarian Forint';
      case 'RUB':
        return 'Russian Ruble';
      case 'BRL':
        return 'Brazilian Real';
      case 'MXN':
        return 'Mexican Peso';
      case 'ARS':
        return 'Argentine Peso';
      case 'CLP':
        return 'Chilean Peso';
      case 'COP':
        return 'Colombian Peso';
      case 'PEN':
        return 'Peruvian Sol';
      case 'VND':
        return 'Vietnamese Dong';
      case 'IDR':
        return 'Indonesian Rupiah';
      case 'PHP':
        return 'Philippine Peso';
      case 'ZAR':
        return 'South African Rand';
      case 'EGP':
        return 'Egyptian Pound';
      case 'NGN':
        return 'Nigerian Naira';
      case 'KES':
        return 'Kenyan Shilling';
      case 'GHS':
        return 'Ghanaian Cedi';
      case 'MAD':
        return 'Moroccan Dirham';
      case 'TND':
        return 'Tunisian Dinar';
      case 'AED':
        return 'UAE Dirham';
      case 'SAR':
        return 'Saudi Riyal';
      case 'QAR':
        return 'Qatari Riyal';
      case 'KWD':
        return 'Kuwaiti Dinar';
      case 'BHD':
        return 'Bahraini Dinar';
      case 'OMR':
        return 'Omani Rial';
      case 'JOD':
        return 'Jordanian Dinar';
      case 'LBP':
        return 'Lebanese Pound';
      case 'ILS':
        return 'Israeli Shekel';
      case 'TRY':
        return 'Turkish Lira';
      case 'UAH':
        return 'Ukrainian Hryvnia';
      case 'RON':
        return 'Romanian Leu';
      case 'BGN':
        return 'Bulgarian Lev';
      case 'HRK':
        return 'Croatian Kuna';
      case 'RSD':
        return 'Serbian Dinar';
      case 'MKD':
        return 'Macedonian Denar';
      case 'ALL':
        return 'Albanian Lek';
      case 'BAM':
        return 'Bosnian Mark';
      default:
        return currency;
    }
  }
}
