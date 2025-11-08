import 'package:flutter/foundation.dart' show protected, nonVirtual;
import 'package:fly_glow_guard/fly_glow_guard.dart';
import 'package:foundation_project/core/database/models/base_entity.dart';
import 'package:foundation_project/core/models/sync_status.dart';
import 'package:foundation_project/core/repositories/interfaces/i_base_repository.dart';

/// Base repository implementation with common functionality
/// Uses Template Method Pattern to enforce hooks on all CRUD operations
abstract class BaseRepository<T extends BaseEntity>
    implements IBaseRepository<T> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;
  final Map<String, dynamic> Function(T) toMap;

  const BaseRepository({
    required this.tableName,
    required this.fromMap,
    required this.toMap,
  });

  // =========================================================================
  // TEMPLATE METHODS (FINAL - ENFORCE HOOKS)
  // =========================================================================

  /// Template method for create operation
  /// Automatically calls beforeCreate hook, then delegates to performCreate
  @override
  @nonVirtual
  Future<AppResult<T>> create(T entity) async {
    await beforeCreate(entity);
    return await performCreate(entity);
  }

  /// Template method for update operation
  /// Automatically calls beforeUpdate hook, then delegates to performUpdate
  @override
  @nonVirtual
  Future<AppResult<T>> update(T entity) async {
    await beforeUpdate(entity);
    return await performUpdate(entity);
  }

  /// Template method for delete operation
  /// Automatically calls beforeDelete hook, then delegates to performDelete
  @override
  @nonVirtual
  Future<AppResult<bool>> delete(String id) async {
    await beforeDelete(id);
    return await performDelete(id);
  }

  // =========================================================================
  // PROTECTED ABSTRACT METHODS (MUST BE IMPLEMENTED BY SUBCLASSES)
  // =========================================================================

  /// Perform the actual create operation
  /// This is called by the create template method after hooks are executed
  @protected
  Future<AppResult<T>> performCreate(T entity);

  /// Perform the actual update operation
  /// This is called by the update template method after hooks are executed
  @protected
  Future<AppResult<T>> performUpdate(T entity);

  /// Perform the actual delete operation
  /// This is called by the delete template method after hooks are executed
  @protected
  Future<AppResult<bool>> performDelete(String id);

  /// Convert database row to entity
  T mapRowToEntity(Map<String, dynamic> row) {
    return fromMap(row);
  }

  /// Convert entity to database row
  Map<String, dynamic> mapEntityToRow(T entity) {
    final row = toMap(entity);

    // Add sync metadata
    row['sync_status'] = entity.syncStatus.name;
    row['last_synced_at'] = entity.lastSyncedAt?.toIso8601String();
    row['version'] = entity.version;

    return row;
  }

  /// Parse sync status from string
  SyncStatus parseSyncStatus(String? status) {
    return SyncStatus.fromJson(status);
  }

  /// Create entity with sync metadata
  T createEntityWithSyncMetadata(
    Map<String, dynamic> row, {
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    int? version,
  }) {
    final entity = mapRowToEntity(row);

    return entity.copyWith(
      syncStatus: syncStatus ?? parseSyncStatus(row['sync_status'] as String?),
      lastSyncedAt: lastSyncedAt ??
          (row['last_synced_at'] != null
              ? DateTime.tryParse(row['last_synced_at'] as String)
              : null),
      version: version ?? (row['version'] as int? ?? 1),
    ) as T;
  }

  /// Validate entity before save
  AppResult<T> validateEntity(T entity) {
    if (entity.id.isEmpty) {
      return Failure('Entity ID cannot be empty');
    }

    return Success(entity);
  }

  /// Handle repository errors
  AppResult<T> handleError(dynamic error, String operation) {
    final errorMessage = 'Failed to $operation: ${error.toString()}';
    return Failure(errorMessage, error);
  }

  /// Handle repository errors for list operations
  AppResult<List<T>> handleListError(dynamic error, String operation) {
    final errorMessage = 'Failed to $operation: ${error.toString()}';
    return Failure(errorMessage, error);
  }

  /// Handle repository errors for boolean operations
  AppResult<bool> handleBooleanError(dynamic error, String operation) {
    final errorMessage = 'Failed to $operation: ${error.toString()}';
    return Failure(errorMessage, error);
  }

  /// Handle repository errors for void operations
  AppResult<void> handleVoidError(dynamic error, String operation) {
    final errorMessage = 'Failed to $operation: ${error.toString()}';
    return Failure(errorMessage, error);
  }

  // =========================================================================
  // HOOKS (CAN BE OVERRIDDEN BY SUBCLASSES)
  // =========================================================================

  /// Hook executed BEFORE any create operation
  Future<void> beforeCreate(T entity) async {
    // Hook available for subclasses to override
  }

  /// Hook executed BEFORE any update operation
  Future<void> beforeUpdate(T entity) async {
    // Hook available for subclasses to override
  }

  /// Hook executed BEFORE any delete operation
  Future<void> beforeDelete(String id) async {
    // Hook available for subclasses to override
  }
}

