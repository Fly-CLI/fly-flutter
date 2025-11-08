import 'dart:async';

import 'package:fly_logger/fly_logger.dart';
import 'package:fly_events/fly_events.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
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
/// This service listens to app events emitted by navigation components.
class RecentlyAccessedTrackingService {
  final AppDataManager _dataManager;
  final AppEventEmitter _lifecycleEmitter;
  final FlyLogger _logger;

  Timer? _debounceTimer;
  FeatureScreenType? _pendingFeature;
  StreamSubscription<Event>? _navigationSubscription;

  RecentlyAccessedTrackingService(
    this._dataManager,
    this._lifecycleEmitter, {
    required FlyLogger logger,
  })  : _logger = logger {
    _initialize();
  }

  /// Initialize the service by subscribing to app events
  void _initialize() {
    // Get navigation stream using type-safe API
    final navigationStream = _lifecycleEmitter.getStreamFor<NavigationEvent>();
    _navigationSubscription = navigationStream.listen(
      (event) {
        if (event is NavigationStartedEvent) {
          // Track when navigation starts (before completion)
          trackFeatureAccess(event.feature);
        } else if (event is NavigationCompletedEvent) {
          // Alternatively, track when navigation completes
          // Using NavigationStartedEvent for consistency with previous behavior
          // where tracking happened before navigation
        }
      },
      onError: (error) {
        _logger.error(
          'Error listening to navigation events: ${error.toString()}',
          stackTrace: StackTrace.current,
        );
      },
    );
  }

  /// Track feature access with debouncing
  ///
  /// If the same feature is accessed repeatedly within debounce window,
  /// only the last access is tracked.
  void trackFeatureAccess(FeatureScreenType feature) {
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
  Future<void> _performTracking(FeatureScreenType feature) async {
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
  Future<List<FeatureScreenType>> getRecentlyAccessed({int limit = _Config.maxItems}) async {
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
  List<FeatureScreenType> _parseFeaturesList(Map<String, dynamic>? json) {
    if (json == null || json['features'] == null) return [];

    try {
      final featuresList = json['features'] as List<dynamic>;
      return featuresList
          .map((f) => FeatureScreenType.values.firstWhere(
                (feature) => feature.name == f,
                orElse: () => FeatureScreenType.home,
              ),)
          .toList();
    } catch (e) {
      _logger.error('Failed to parse features list: ${e.toString()}', stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Convert features list to JSON
  Map<String, dynamic> _featuresToJson(List<FeatureScreenType> features) {
    return {
      'features': features.map((f) => f.name).toList(),
    };
  }

  /// Dispose resources
  ///
  /// Cancels any pending timers and stream subscriptions to prevent memory leaks.
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _navigationSubscription?.cancel();
    _navigationSubscription = null;
  }
}
