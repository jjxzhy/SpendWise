/// Application configuration loaded from compile-time `--dart-define` flags.
///
/// Example cloud/CI build:
/// ```bash
/// flutter build web --release \
///   --dart-define=APP_ENV=production \
///   --dart-define=API_BASE_URL=https://api.example.com \
///   --dart-define=DEFAULT_CURRENCY=USD \
///   --dart-define=DEFAULT_MONTHLY_BUDGET=0
/// ```
class AppConfig {
  const AppConfig._();

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'SpendWise',
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  /// Optional REST API base URL for future cloud/remote repository backends.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Storage backend identifier (e.g., `local` for Hive/IndexedDB, `remote` for REST API).
  static const String storageBackend = String.fromEnvironment(
    'STORAGE_BACKEND',
    defaultValue: 'local',
  );

  static const String defaultCurrency = String.fromEnvironment(
    'DEFAULT_CURRENCY',
    defaultValue: 'EUR',
  );

  static const String _defaultMonthlyBudgetRaw = String.fromEnvironment(
    'DEFAULT_MONTHLY_BUDGET',
    defaultValue: '0',
  );

  static double get defaultMonthlyBudget {
    final parsed = double.tryParse(_defaultMonthlyBudgetRaw);
    if (parsed != null && parsed >= 0) {
      return parsed;
    }
    return 0.0;
  }

  static const String expensesBoxName = String.fromEnvironment(
    'HIVE_EXPENSES_BOX',
    defaultValue: 'expenses',
  );

  static const String settingsBoxName = String.fromEnvironment(
    'HIVE_SETTINGS_BOX',
    defaultValue: 'settings',
  );

  static bool get hasRemoteApi => apiBaseUrl.trim().isNotEmpty;
}
