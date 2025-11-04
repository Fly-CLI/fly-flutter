import 'package:foundation_project/core/storage/managers/app_data_manager.dart';
import 'package:foundation_project/core/storage/models/storage_key.dart';

/// Specialized manager for sync data
///
/// Handles storage of sync-related data including last sync timestamp,
/// sync status, and pending operations count.
class SyncDataManager {
  final AppDataManager _dataManager;

  SyncDataManager(this._dataManager);

  /// Set the last sync timestamp
  Future<void> setLastSyncTimestamp(DateTime? timestamp) async {
    if (timestamp != null) {
      await _dataManager.setString(
        StorageKey.lastSyncTimestamp,
        timestamp.toIso8601String(),
      );
    } else {
      await _dataManager.remove(StorageKey.lastSyncTimestamp);
    }
  }

  /// Get the last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final timestampString =
        await _dataManager.getString(StorageKey.lastSyncTimestamp);
    if (timestampString == null) return null;
    try {
      return DateTime.parse(timestampString);
    } catch (e) {
      return null;
    }
  }

  /// Set the sync status
  Future<void> setSyncStatus(String? status) async {
    if (status != null) {
      await _dataManager.setString(StorageKey.syncStatus, status);
    } else {
      await _dataManager.remove(StorageKey.syncStatus);
    }
  }

  /// Get the sync status
  Future<String?> getSyncStatus() async {
    return await _dataManager.getString(StorageKey.syncStatus);
  }

  /// Set the pending operations count
  Future<void> setPendingOperationsCount(int count) async {
    await _dataManager.setInt(StorageKey.pendingOperationsCount, count);
  }

  /// Get the pending operations count
  Future<int> getPendingOperationsCount() async {
    return await _dataManager.getInt(StorageKey.pendingOperationsCount) ?? 0;
  }
}

