/// Interface for regular storage operations using SharedPreferences
///
/// This interface defines the contract for storing and retrieving
/// non-sensitive data in the application.
abstract class IStorageService {
  /// Initialize the storage service
  Future<void> init();

  /// Store a string value
  Future<void> setString(String key, String value);

  /// Retrieve a string value
  Future<String?> getString(String key);

  /// Store a boolean value
  Future<void> setBool(String key, bool value);

  /// Retrieve a boolean value
  Future<bool?> getBool(String key);

  /// Store an integer value
  Future<void> setInt(String key, int value);

  /// Retrieve an integer value
  Future<int?> getInt(String key);

  /// Store a double value
  Future<void> setDouble(String key, double value);

  /// Retrieve a double value
  Future<double?> getDouble(String key);

  /// Store a list of strings
  Future<void> setStringList(String key, List<String> value);

  /// Retrieve a list of strings
  Future<List<String>?> getStringList(String key);

  /// Remove a key from storage
  Future<void> remove(String key);

  /// Clear all data from storage
  Future<void> clear();

  /// Check if a key exists in storage
  Future<bool> containsKey(String key);

  /// Get all keys in storage
  Future<Set<String>> getKeys();
}

