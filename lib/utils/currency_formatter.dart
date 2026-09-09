import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static const Map<String, String> symbols = {
    'EUR': '€',
    'USD': r'$',
    'GBP': '£',
    'INR': '₹',
  };

  static String symbolFor(String currencyCode) {
    return symbols[currencyCode] ?? '€';
  }

  static String format(double amount, {String currencyCode = 'EUR'}) {
    return NumberFormat.currency(
      symbol: symbolFor(currencyCode),
      decimalDigits: 2,
    ).format(amount);
  }
}
