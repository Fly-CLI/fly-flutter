import 'dart:convert';

import 'package:foundation_project/foundation/storage/interfaces/i_secure_storage_service.dart';
import 'package:foundation_project/foundation/storage/interfaces/i_storage_service.dart';
import 'package:foundation_project/core/storage/models/storage_key.dart';
import 'package:foundation_project/core/storage/models/storage_type.dart';

/// Main data manager that handles both regular and secure storage
///
/// This manager automatically routes data to the appropriate storage
/// backend based on the [StorageKey]'s classification:
/// - [StorageType.regular] → [IStorageService] (SharedPreferences)
/// - [StorageType.secure] → [ISecureStorageService] (FlutterSecureStorage)
class AppDataManager {
  final IStorageService _regularStorage;
  final ISecureStorageService _secureStorage;

  AppDataManager({
    required IStorageService regularStorage,
    required ISecureStorageService secureStorage,
  })  : _regularStorage = regularStorage,
        _secureStorage = secureStorage;

  /// Initialize both storage services
  Future<void> init() async {
    await _regularStorage.init();
    await _secureStorage.init();
  }

  /// Store a string value
  Future<void> setString(StorageKey key, String value) async {
    switch (key.storageType) {
      case StorageType.regular:
        await _regularStorage.setString(key.key, value);
        break;
      case StorageType.secure:
        await _secureStorage.write(key: key.key, value: value);
        break;
    }
  }

  /// Retrieve a string value
  Future<String?> getString(StorageKey key) async {
    switch (key.storageType) {
      case StorageType.regular:
        return await _regularStorage.getString(key.key);
      case StorageType.secure:
        return await _secureStorage.read(key: key.key);
    }
  }

  /// Store a boolean value
  Future<void> setBool(StorageKey key, bool value) async {
    switch (key.storageType) {
      case StorageType.regular:
        await _regularStorage.setBool(key.key, value);
        break;
      case StorageType.secure:
        await _secureStorage.write(key: key.key, value: value.toString());
        break;
    }
  }

  /// Retrieve a boolean value
  Future<bool?> getBool(StorageKey key) async {
    switch (key.storageType) {
      case StorageType.regular:
        return await _regularStorage.getBool(key.key);
      case StorageType.secure:
        final value = await _secureStorage.read(key: key.key);
        if (value == null) return null;
        return value.toLowerCase() == 'true';
    }
  }

  /// Store an integer value
  Future<void> setInt(StorageKey key, int value) async {
    switch (key.storageType) {
      case StorageType.regular:
        await _regularStorage.setInt(key.key, value);
        break;
      case StorageType.secure:
        await _secureStorage.write(key: key.key, value: value.toString());
        break;
    }
  }

  /// Retrieve an integer value
  Future<int?> getInt(StorageKey key) async {
    switch (key.storageType) {
      case StorageType.regular:
        return await _regularStorage.getInt(key.key);
      case StorageType.secure:
        final value = await _secureStorage.read(key: key.key);
        if (value == null) return null;
        return int.tryParse(value);
    }
  }

  /// Store a JSON object
  Future<void> setJson(StorageKey key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await setString(key, jsonString);
  }

  /// Retrieve a JSON object
  Future<Map<String, dynamic>?> getJson(StorageKey key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove a key from storage
  Future<void> remove(StorageKey key) async {
    switch (key.storageType) {
      case StorageType.regular:
        await _regularStorage.remove(key.key);
        break;
      case StorageType.secure:
        await _secureStorage.delete(key: key.key);
        break;
    }
  }

  /// Check if a key exists in storage
  Future<bool> containsKey(StorageKey key) async {
    switch (key.storageType) {
      case StorageType.regular:
        return await _regularStorage.containsKey(key.key);
      case StorageType.secure:
        return await _secureStorage.containsKey(key: key.key);
    }
  }
}

