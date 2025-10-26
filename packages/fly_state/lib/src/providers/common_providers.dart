import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'common_providers.g.dart';

/// Provider for app configuration
@riverpod
class AppConfigProvider extends _$AppConfigProvider {
  @override
  AppConfig build() {
    return const AppConfig(
      appName: 'Fly App',
      version: '1.0.0',
      buildNumber: 1,
      isDebug: false,
    );
  }
  
  /// Update app configuration
  void updateConfig(AppConfig config) {
    state = config;
  }
}

/// App configuration model
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.isDebug,
  });
  
  final String appName;
  final String version;
  final int buildNumber;
  final bool isDebug;
  
  AppConfig copyWith({
    String? appName,
    String? version,
    int? buildNumber,
    bool? isDebug,
  }) {
    return AppConfig(
      appName: appName ?? this.appName,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      isDebug: isDebug ?? this.isDebug,
    );
  }
}

/// Provider for user preferences
@riverpod
class UserPreferencesProvider extends _$UserPreferencesProvider {
  @override
  UserPreferences build() {
    return const UserPreferences(
      themeMode: ThemeMode.system,
      locale: 'en',
      notificationsEnabled: true,
      analyticsEnabled: false,
    );
  }
  
  /// Update theme mode
  void updateThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }
  
  /// Update locale
  void updateLocale(String locale) {
    state = state.copyWith(locale: locale);
  }
  
  /// Toggle notifications
  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
  }
  
  /// Toggle analytics
  void toggleAnalytics() {
    state = state.copyWith(analyticsEnabled: !state.analyticsEnabled);
  }
}

/// User preferences model
class UserPreferences {
  const UserPreferences({
    required this.themeMode,
    required this.locale,
    required this.notificationsEnabled,
    required this.analyticsEnabled,
  });
  
  final ThemeMode themeMode;
  final String locale;
  final bool notificationsEnabled;
  final bool analyticsEnabled;
  
  UserPreferences copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

/// Provider for app state
@riverpod
class AppStateProvider extends _$AppStateProvider {
  @override
  AppState build() {
    return const AppState(
      isInitialized: false,
      isOnline: true,
      currentRoute: '/',
    );
  }
  
  /// Mark app as initialized
  void markAsInitialized() {
    state = state.copyWith(isInitialized: true);
  }
  
  /// Update online status
  void updateOnlineStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }
  
  /// Update current route
  void updateCurrentRoute(String route) {
    state = state.copyWith(currentRoute: route);
  }
}

/// App state model
class AppState {
  const AppState({
    required this.isInitialized,
    required this.isOnline,
    required this.currentRoute,
  });
  
  final bool isInitialized;
  final bool isOnline;
  final String currentRoute;
  
  AppState copyWith({
    bool? isInitialized,
    bool? isOnline,
    String? currentRoute,
  }) {
    return AppState(
      isInitialized: isInitialized ?? this.isInitialized,
      isOnline: isOnline ?? this.isOnline,
      currentRoute: currentRoute ?? this.currentRoute,
    );
  }
}

/// Provider for loading states
@riverpod
class LoadingStateProvider extends _$LoadingStateProvider {
  @override
  Map<String, bool> build() {
    return {};
  }
  
  /// Set loading state for a specific key
  void setLoading(String key, bool isLoading) {
    state = {...state, key: isLoading};
  }
  
  /// Check if a specific key is loading
  bool isLoading(String key) => state[key] ?? false;
  
  /// Check if any key is loading
  bool get isAnyLoading => state.values.any((loading) => loading);
  
  /// Clear all loading states
  void clearAll() {
    state = {};
  }
}

/// Provider for error states
@riverpod
class ErrorStateProvider extends _$ErrorStateProvider {
  @override
  Map<String, String> build() {
    return {};
  }
  
  /// Set error for a specific key
  void setError(String key, String error) {
    state = {...state, key: error};
  }
  
  /// Clear error for a specific key
  void clearError(String key) {
    final newState = Map<String, String>.from(state);
    newState.remove(key);
    state = newState;
  }
  
  /// Get error for a specific key
  String? getError(String key) => state[key];
  
  /// Check if a specific key has error
  bool hasError(String key) => state.containsKey(key);
  
  /// Clear all errors
  void clearAll() {
    state = {};
  }
}
