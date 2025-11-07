import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/storage/implementations/secure_storage_service.dart';
import 'package:foundation_project/core/storage/implementations/shared_preferences_storage_service.dart';
import 'package:foundation_project/core/storage/interfaces/i_secure_storage_service.dart';
import 'package:foundation_project/core/storage/interfaces/i_storage_service.dart';
import 'package:foundation_project/core/storage/managers/app_config_data_manager.dart';
import 'package:foundation_project/core/storage/managers/app_data_manager.dart';
import 'package:foundation_project/core/storage/managers/sync_data_manager.dart';

/// Provider for regular storage service (SharedPreferences)
final regularStorageProvider = Provider<IStorageService>((ref) {
  return SharedPreferencesStorageService();
});

/// Provider for secure storage service (FlutterSecureStorage)
final secureStorageProvider = Provider<ISecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for the main app data manager
final appDataManagerProvider = Provider<AppDataManager>((ref) {
  return AppDataManager(
    regularStorage: ref.watch(regularStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Provider for app configuration data manager
final appConfigDataManagerProvider = Provider<AppConfigDataManager>((ref) {
  return AppConfigDataManager(ref.watch(appDataManagerProvider));
});

/// Provider for sync data manager
final syncDataManagerProvider = Provider<SyncDataManager>((ref) {
  return SyncDataManager(ref.watch(appDataManagerProvider));
});

