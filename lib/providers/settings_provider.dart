import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settingsBox);

  static const String budgetKey = 'monthlyBudget';
  static const String currencyKey = 'currencyCode';
  static const String themeKey = 'themeMode';
  static const String sampleDataSeededKey = 'sampleDataSeeded';

  final Box<dynamic> _settingsBox;

  double get monthlyBudget {
    final value = _settingsBox.get(budgetKey, defaultValue: 800.0);
    if (value is num && value > 0) {
      return value.toDouble();
    }
    return 800.0;
  }

  String get currencyCode {
    return (_settingsBox.get(currencyKey, defaultValue: 'EUR') as String?) ??
        'EUR';
  }

  ThemeMode get themeMode {
    final stored =
        _settingsBox.get(themeKey, defaultValue: 'system') as String?;
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  bool get sampleDataSeeded {
    return _settingsBox.get(sampleDataSeededKey, defaultValue: false) == true;
  }

  Future<void> saveMonthlyBudget(double budget) async {
    if (budget <= 0) {
      throw ArgumentError('Budget must be greater than zero.');
    }
    await _settingsBox.put(budgetKey, budget);
    notifyListeners();
  }

  Future<void> saveCurrencyCode(String currencyCode) async {
    await _settingsBox.put(currencyKey, currencyCode);
    notifyListeners();
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final value = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settingsBox.put(themeKey, value);
    notifyListeners();
  }

  Future<void> markSampleDataSeeded() async {
    await _settingsBox.put(sampleDataSeededKey, true);
  }
}
