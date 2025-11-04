import 'dart:async';

import 'package:foundation_project/core/foundation/utils/app_logger.dart';
import 'package:foundation_project/core/navigation/app_navigation.dart';
import 'package:foundation_project/core/storage/managers/app_data_manager.dart';
import 'package:foundation_project/core/storage/models/storage_key.dart';

/// Configuration constants for recently accessed tracking
class _Config {
  /// Maximum number of recently accessed items to keep
  static const int maxItems = 8;

  /// Debounce window to prevent duplicate tracking
  static const Duration debounceWindow = Duration(milliseconds: 500);
}

/// Service for tracking recently accessed features
///
/// Handles automatic tracking with debouncing, exclusion, and error handling.
/// This service is automatically called when users navigate to features via
/// AppNavigation methods.
class RecentlyAccessedTrackingService {
  final AppDataManager _dataManager;
  final AppLogger _logger = AppLogger('RecentlyAccessedTrackingService');

  Timer? _debounceTimer;
  Feature? _pendingFeature;

  RecentlyAccessedTrackingService(this._dataManager);

  /// Track feature access with debouncing
  ///
  /// If the same feature is accessed repeatedly within debounce window,
  /// only the last access is tracked.
  void trackFeatureAccess(Feature feature) {
    // Cancel existing timer
    _debounceTimer?.cancel();

    // Store pending feature
    _pendingFeature = feature;

    // Start new debounce timer
    _debounceTimer = Timer(_Config.debounceWindow, () {
      _performTracking(_pendingFeature!);
    });
  }

  /// Perform the actual tracking
  Future<void> _performTracking(Feature feature) async {
    try {
      // Get current recently accessed features
      final recentFeaturesJson =
          await _dataManager.getJson(StorageKey.recentlyAccessedFeatures);
      final recentFeatures = _parseFeaturesList(recentFeaturesJson);

      // Remove if already exists (to move to top)
      recentFeatures.removeWhere((f) => f.name == feature.name);

      // Add to beginning
      recentFeatures.insert(0, feature);

      // Limit to max items
      if (recentFeatures.length > _Config.maxItems) {
        recentFeatures.removeRange(_Config.maxItems, recentFeatures.length);
      }

      // Save back to storage
      await _dataManager.setJson(
        StorageKey.recentlyAccessedFeatures,
        _featuresToJson(recentFeatures),
      );

      _logger.debug('Tracked access: ${feature.name}');
    } catch (e, stackTrace) {
      // Log but don't throw - tracking failures shouldn't break navigation
      _logger.error(
        'Failed to track feature access: ${feature.name}: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  /// Get recently accessed features
  Future<List<Feature>> getRecentlyAccessed({int limit = _Config.maxItems}) async {
    try {
      final recentFeaturesJson =
          await _dataManager.getJson(StorageKey.recentlyAccessedFeatures);
      final recentFeatures = _parseFeaturesList(recentFeaturesJson);

      return recentFeatures.take(limit).toList();
    } catch (e) {
      _logger.error('Failed to get recently accessed features: ${e.toString()}', stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Clear recently accessed features
  Future<void> clearRecentlyAccessed() async {
    try {
      await _dataManager.remove(StorageKey.recentlyAccessedFeatures);
    } catch (e) {
      _logger.error('Failed to clear recently accessed features: ${e.toString()}', stackTrace: StackTrace.current);
    }
  }

  /// Parse features list from JSON
  List<Feature> _parseFeaturesList(Map<String, dynamic>? json) {
    if (json == null || json['features'] == null) return [];

    try {
      final featuresList = json['features'] as List<dynamic>;
      return featuresList
          .map((f) => Feature.values.firstWhere(
                (feature) => feature.name == f,
                orElse: () => Feature.home,
              ))
          .toList();
    } catch (e) {
      _logger.error('Failed to parse features list: ${e.toString()}', stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Convert features list to JSON
  Map<String, dynamic> _featuresToJson(List<Feature> features) {
    return {
      'features': features.map((f) => f.name).toList(),
    };
  }

  /// Dispose resources
  ///
  /// Cancels any pending timers to prevent memory leaks.
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

