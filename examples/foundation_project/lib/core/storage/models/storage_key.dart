import 'package:foundation_project/core/storage/models/storage_type.dart';

/// Enum representing all storage keys with their storage type classification
///
/// This enum defines all keys used for data persistence in the foundation project.
/// Each key is classified as either [StorageType.regular] (SharedPreferences)
/// or [StorageType.secure] (FlutterSecureStorage).
enum StorageKey {
  // =====================
  // App Configuration
  // =====================

  /// App theme mode (light, dark, system)
  appTheme(StorageType.regular),

  /// App locale
  appLocale(StorageType.regular),

  /// Whether app is first launch
  isFirstLaunch(StorageType.regular),

  // =====================
  // Sync Configuration
  // =====================

  /// Last sync timestamp
  lastSyncTimestamp(StorageType.regular),

  /// Sync status
  syncStatus(StorageType.regular),

  /// Pending operations count
  pendingOperationsCount(StorageType.regular),

  // =====================
  // Task Configuration
  // =====================

  /// Task filter preferences (JSON)
  taskFilters(StorageType.regular),

  /// Task sort preferences (JSON)
  taskSortPreferences(StorageType.regular),

  // =====================
  // Note Configuration
  // =====================

  /// Note filter preferences (JSON)
  noteFilters(StorageType.regular),

  /// Note sort preferences (JSON)
  noteSortPreferences(StorageType.regular),

  // =====================
  // Recently Accessed
  // =====================

  /// Recently accessed features (JSON array)
  recentlyAccessedFeatures(StorageType.regular),

  // =====================
  // Secure Data
  // =====================

  /// Authentication token (if needed)
  authToken(StorageType.secure),

  /// User ID (if needed)
  userId(StorageType.secure);

  const StorageKey(this.storageType);

  final StorageType storageType;

  /// Get the string key for storage operations
  String get key => name;
}

