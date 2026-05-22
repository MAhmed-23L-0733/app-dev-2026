import 'package:flutter/foundation.dart';

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.usdToCurrencyRate,
  });

  final String code;
  final String symbol;
  final String name;
  final double usdToCurrencyRate;

  String get label => '$code - $name';
}

class CurrencyPreferenceController {
  CurrencyPreferenceController._();

  static final CurrencyPreferenceController instance =
      CurrencyPreferenceController._();

  static const List<CurrencyOption> options = <CurrencyOption>[
    CurrencyOption(
      code: 'USD',
      symbol: r'$',
      name: 'US Dollar',
      usdToCurrencyRate: 1.0,
    ),
    CurrencyOption(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      usdToCurrencyRate: 0.92,
    ),
    CurrencyOption(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      usdToCurrencyRate: 0.78,
    ),
    CurrencyOption(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      usdToCurrencyRate: 83.0,
    ),
    CurrencyOption(
      code: 'PKR',
      symbol: 'Rs',
      name: 'Pakistani Rupee',
      usdToCurrencyRate: 278.0,
    ),
    CurrencyOption(
      code: 'AED',
      symbol: 'د.إ',
      name: 'UAE Dirham',
      usdToCurrencyRate: 3.67,
    ),
  ];

  final ValueNotifier<String> currencyCode = ValueNotifier<String>('PKR');

  String get currentCode => currencyCode.value;

  CurrencyOption get currentOption => optionFor(currentCode);

  CurrencyOption optionFor(String code) {
    return options.firstWhere(
      (CurrencyOption option) => option.code == code,
      orElse: () => options.first,
    );
  }

  void setCurrencyCode(String code) {
    final String normalizedCode = optionFor(code).code;
    if (currencyCode.value != normalizedCode) {
      currencyCode.value = normalizedCode;
    }
  }

  double fromBaseAmount(double amountInUsd, String currencyCode) {
    return amountInUsd * optionFor(currencyCode).usdToCurrencyRate;
  }

  double toBaseAmount(double amountInCurrency, String currencyCode) {
    final double rate = optionFor(currencyCode).usdToCurrencyRate;
    if (rate == 0) {
      return amountInCurrency;
    }

    return amountInCurrency / rate;
  }

  String formatBaseAmount(double amountInUsd, String currencyCode) {
    final CurrencyOption option = optionFor(currencyCode);
    final double converted = fromBaseAmount(amountInUsd, option.code);
    final String sign = converted < 0 ? '-' : '';
    return '$sign${option.symbol} ${converted.abs().toStringAsFixed(2)}';
  }

  String currencyDisplay(String code) {
    final CurrencyOption option = optionFor(code);
    return '${option.symbol} ${option.code}';
  }
}
