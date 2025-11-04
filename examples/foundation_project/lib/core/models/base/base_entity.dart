import 'package:foundation_project/core/models/base/sync_status.dart';

/// Base entity class that all domain models extend
/// Provides common fields and functionality with sync metadata
abstract class BaseEntity {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;

  const BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.version = 1,
  });

  /// Check if entity needs synchronization
  bool get needsSync => syncStatus.needsSync;

  /// Check if entity has sync conflicts
  bool get isConflicted => syncStatus.isConflicted;

  /// Check if entity sync failed
  bool get syncFailed => syncStatus.syncFailed;

  /// Check if entity is synced
  bool get isSynced => syncStatus.isSynced;

  /// Get the table name for database operations
  String get tableName;

  /// Create a copy of this entity with updated fields
  BaseEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    int? version,
  });

  /// Mark entity as synced
  BaseEntity markAsSynced() {
    return copyWith(
      syncStatus: SyncStatus.synced,
      lastSyncedAt: DateTime.now(),
      version: version + 1,
    );
  }

  /// Mark entity as conflicted
  BaseEntity markAsConflicted() {
    return copyWith(
      syncStatus: SyncStatus.conflicted,
      version: version + 1,
    );
  }

  /// Mark entity as failed
  BaseEntity markAsFailed() {
    return copyWith(
      syncStatus: SyncStatus.failed,
      version: version + 1,
    );
  }

  /// Mark entity as pending
  BaseEntity markAsPending() {
    return copyWith(syncStatus: SyncStatus.pending);
  }
}

