import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/services/api_service.dart';
import 'package:foundation_project/core/services/cache_service.dart';
import 'package:foundation_project/core/services/pagination/note_pagination_service.dart';
import 'package:foundation_project/core/services/pagination/task_pagination_service.dart';
import 'package:foundation_project/core/services/statistics_service.dart';
import 'package:foundation_project/core/services/sync_service.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/providers/logger_provider.dart';
import 'package:foundation_project/core/storage/storage_providers.dart';

/// Provider for cache service
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService(
    logger: ref.watch(loggerProvider('CacheService')),
  );
});

/// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    logger: ref.watch(loggerProvider('ApiService')),
  );
});

/// Provider for statistics service
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService(
    taskRepository: ref.watch(taskRepositoryProvider),
    cacheService: ref.watch(cacheServiceProvider),
    logger: ref.watch(loggerProvider('StatisticsService')),
  );
});

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    taskRepository: ref.watch(taskRepositoryProvider),
    noteRepository: ref.watch(noteRepositoryProvider),
    apiService: ref.watch(apiServiceProvider),
    syncDataManager: ref.watch(syncDataManagerProvider),
    logger: ref.watch(loggerProvider('SyncService')),
  );
});

/// Provider for task pagination service
final taskPaginationServiceProvider = Provider<TaskPaginationService>((ref) {
  return TaskPaginationService(
    ref.watch(taskRepositoryProvider),
    logger: ref.watch(loggerProvider('TaskPaginationService')),
  );
});

/// Provider for note pagination service
final notePaginationServiceProvider = Provider<NotePaginationService>((ref) {
  return NotePaginationService(
    ref.watch(noteRepositoryProvider),
    logger: ref.watch(loggerProvider('NotePaginationService')),
  );
});

