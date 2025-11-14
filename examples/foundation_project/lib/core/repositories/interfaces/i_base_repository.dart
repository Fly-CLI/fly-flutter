import 'package:fly_flow_guard/fly_flow_guard.dart';
import 'package:foundation_project/core/database/models/base_entity.dart';

/// Base repository interface for all data operations
/// Supports different data sources (local, remote, hybrid)
abstract class IBaseRepository<T extends BaseEntity> {
  /// Get all entities
  Future<AppResult<List<T>>> getAll();

  /// Get entity by ID
  Future<AppResult<T?>> getById(String id);

  /// Create new entity
  Future<AppResult<T>> create(T entity);

  /// Update existing entity
  Future<AppResult<T>> update(T entity);

  /// Delete entity by ID
  Future<AppResult<bool>> delete(String id);

  /// Search entities by query
  Future<AppResult<List<T>>> search(String query);

  /// Get entities that need synchronization
  Future<AppResult<List<T>>> getPendingSync();

  /// Mark entity as synced
  Future<AppResult<void>> markAsSynced(String id, DateTime syncedAt);

  /// Mark entity as conflicted
  Future<AppResult<void>> markAsConflicted(String id);

  /// Mark entity as failed
  Future<AppResult<void>> markAsFailed(String id, String errorMessage);
}

