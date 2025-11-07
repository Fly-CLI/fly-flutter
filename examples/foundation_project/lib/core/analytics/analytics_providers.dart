import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/analytics/recently_accessed_tracking_service.dart';
import 'package:foundation_project/core/event_system/event_providers.dart';
import 'package:foundation_project/core/storage/storage_providers.dart';

/// Provider for recently accessed tracking service
final recentlyAccessedTrackingServiceProvider =
    Provider<RecentlyAccessedTrackingService>((ref) {
  return RecentlyAccessedTrackingService(
    ref.watch(appDataManagerProvider),
    ref.watch(eventEmitterProvider),
  );
});

