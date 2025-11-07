/// Interface for secure storage operations using FlutterSecureStorage
///
/// This interface defines the contract for storing and retrieving
/// sensitive data (tokens, passwords, keys) in encrypted storage.
abstract class ISecureStorageService {
  /// Initialize the secure storage service
  Future<void> init();

  /// Write a value to secure storage
  Future<void> write({required String key, required String value});

  /// Read a value from secure storage
  Future<String?> read({required String key});

  /// Delete a value from secure storage
  Future<void> delete({required String key});

  /// Delete all values from secure storage
  Future<void> deleteAll();

  /// Check if a key exists in secure storage
  Future<bool> containsKey({required String key});

  /// Read all values from secure storage
  Future<Map<String, String>> readAll();
}

