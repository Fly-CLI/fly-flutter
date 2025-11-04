import 'package:foundation_project/core/storage/managers/app_data_manager.dart';
import 'package:foundation_project/core/storage/models/storage_key.dart';

/// Specialized manager for app configuration and settings
///
/// Handles storage of app-wide configuration including theme,
/// language, and other user preferences.
class AppConfigDataManager {
  final AppDataManager _dataManager;

  AppConfigDataManager(this._dataManager);

  /// Set the app theme mode
  Future<void> setTheme(String? themeMode) async {
    if (themeMode != null) {
      await _dataManager.setString(StorageKey.appTheme, themeMode);
    } else {
      await _dataManager.remove(StorageKey.appTheme);
    }
  }

  /// Get the app theme mode
  Future<String?> getTheme() async {
    return await _dataManager.getString(StorageKey.appTheme);
  }

  /// Set the app locale
  Future<void> setLocale(String? locale) async {
    if (locale != null) {
      await _dataManager.setString(StorageKey.appLocale, locale);
    } else {
      await _dataManager.remove(StorageKey.appLocale);
    }
  }

  /// Get the app locale
  Future<String?> getLocale() async {
    return await _dataManager.getString(StorageKey.appLocale);
  }

  /// Set whether app is first launch
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _dataManager.setBool(StorageKey.isFirstLaunch, isFirstLaunch);
  }

  /// Get whether app is first launch
  Future<bool> getFirstLaunch() async {
    return await _dataManager.getBool(StorageKey.isFirstLaunch) ?? true;
  }
}

