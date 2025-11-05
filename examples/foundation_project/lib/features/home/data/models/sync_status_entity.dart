import 'package:foundation_project/core/models/sync_status.dart' as core_sync;

/// Sync status entity for home screen
class SyncStatusEntity {
  final core_sync.SyncStatus status;
  final DateTime? lastSync;
  final int pendingOperations;
  final bool isSyncing;
  final String? errorMessage;

  const SyncStatusEntity({
    required this.status,
    this.lastSync,
    this.pendingOperations = 0,
    this.isSyncing = false,
    this.errorMessage,
  });

  /// Create empty sync status
  factory SyncStatusEntity.initial() {
    return const SyncStatusEntity(
      status: core_sync.SyncStatus.idle,
      pendingOperations: 0,
      isSyncing: false,
    );
  }

  /// Copy with new values
  SyncStatusEntity copyWith({
    core_sync.SyncStatus? status,
    DateTime? lastSync,
    int? pendingOperations,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return SyncStatusEntity(
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'SyncStatusEntity(status: $status, lastSync: $lastSync, pendingOperations: $pendingOperations, isSyncing: $isSyncing, errorMessage: $errorMessage)';
  }
}

