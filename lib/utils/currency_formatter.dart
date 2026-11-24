import 'package:intl/intl.dart';

import '../config/app_config.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static const Map<String, String> symbols = {
    'EUR': '€',
    'USD': r'$',
    'GBP': '£',
    'INR': '₹',
  };

  static String symbolFor(String currencyCode) {
    return symbols[currencyCode] ?? symbols[AppConfig.defaultCurrency] ?? '€';
  }

  static String format(double amount, {String? currencyCode}) {
    final resolvedCode = currencyCode ?? AppConfig.defaultCurrency;
    return NumberFormat.currency(
      symbol: symbolFor(resolvedCode),
      decimalDigits: 2,
    ).format(amount);
  }
}
