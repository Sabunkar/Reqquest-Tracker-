class AppConstants {
  const AppConstants._();

  static const String appName = 'Tracker';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyRequests = 'rf_requests_data';
  static const String keyRequestActivities = 'rf_request_activities_data';
  static const String keyStorageInitialized = 'rf_storage_initialized';
  static const String keyUserRole = 'rf_user_role';
  static const String keyThemeMode = 'rf_theme_mode';
  static const String keySimulateFailure = 'rf_simulate_failure';
  static const String keyUnsavedCreateTitle = 'rf_unsaved_create_title';
  static const String keyUnsavedCreateDescription =
      'rf_unsaved_create_description';

  // Validation Limits
  static const int titleMinLength = 3;
  static const int titleMaxLength = 120;
  static const int descriptionMaxLength = 2000;
  static const int rejectionReasonMaxLength = 500;
}
