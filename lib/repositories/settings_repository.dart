import 'package:hive_flutter/hive_flutter.dart';

/// Persistence contract for user settings and preferences.
abstract class SettingsRepository {
  double? getMonthlyBudget();
  Future<void> saveMonthlyBudget(double budget);

  String? getCurrencyCode();
  Future<void> saveCurrencyCode(String currencyCode);

  String? getThemeMode();
  Future<void> saveThemeMode(String themeMode);

  Future<void> clear();
}

/// Web- and mobile-compatible local implementation backed by Hive
/// (uses IndexedDB on Flutter Web and local files on native platforms).
class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  static const String budgetKey = 'monthlyBudget';
  static const String currencyKey = 'currencyCode';
  static const String themeKey = 'themeMode';

  final Box<dynamic> _box;

  @override
  double? getMonthlyBudget() {
    final value = _box.get(budgetKey);
    if (value is num && value >= 0) {
      return value.toDouble();
    }
    return null;
  }

  @override
  Future<void> saveMonthlyBudget(double budget) {
    return _box.put(budgetKey, budget);
  }

  @override
  String? getCurrencyCode() {
    final value = _box.get(currencyKey);
    return value is String ? value : null;
  }

  @override
  Future<void> saveCurrencyCode(String currencyCode) {
    return _box.put(currencyKey, currencyCode);
  }

  @override
  String? getThemeMode() {
    final value = _box.get(themeKey);
    return value is String ? value : null;
  }

  @override
  Future<void> saveThemeMode(String themeMode) {
    return _box.put(themeKey, themeMode);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
