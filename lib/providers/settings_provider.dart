import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository);

  final SettingsRepository _repository;

  double get monthlyBudget {
    final stored = _repository.getMonthlyBudget();
    if (stored != null && stored >= 0) {
      return stored;
    }
    return AppConfig.defaultMonthlyBudget;
  }

  bool get hasMonthlyBudget => monthlyBudget > 0;

  String get currencyCode {
    return _repository.getCurrencyCode() ?? AppConfig.defaultCurrency;
  }

  ThemeMode get themeMode {
    final stored = _repository.getThemeMode() ?? 'system';
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveMonthlyBudget(double budget) async {
    if (budget < 0) {
      throw ArgumentError('Budget cannot be negative.');
    }
    await _repository.saveMonthlyBudget(budget);
    notifyListeners();
  }

  Future<void> saveCurrencyCode(String currencyCode) async {
    await _repository.saveCurrencyCode(currencyCode);
    notifyListeners();
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final value = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _repository.saveThemeMode(value);
    notifyListeners();
  }

  Future<void> resetAllSettings() async {
    await _repository.clear();
    notifyListeners();
  }
}
