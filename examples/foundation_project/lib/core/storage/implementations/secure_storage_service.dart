import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:foundation_project/foundation/storage/interfaces/i_secure_storage_service.dart';

/// Implementation of [ISecureStorageService] using FlutterSecureStorage
///
/// This service handles sensitive data storage (tokens, passwords, keys)
/// using the flutter_secure_storage package with platform-specific
/// encryption (Keychain on iOS, KeyStore on Android).
class SecureStorageService implements ISecureStorageService {
  FlutterSecureStorage? _storage;

  @override
  Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  FlutterSecureStorage get _secureStorage {
    if (_storage == null) {
      throw StateError(
        'SecureStorageService not initialized. Call init() first.',
      );
    }
    return _storage!;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return await _secureStorage.containsKey(key: key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return await _secureStorage.readAll();
  }
}

