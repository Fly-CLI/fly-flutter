import 'package:foundation_project/core/foundation/operations/result.dart';
import 'package:foundation_project/core/foundation/utils/app_logger.dart';
import 'package:foundation_project/core/models/sync_status.dart' as core_sync;
import 'package:foundation_project/core/repositories/note_repository.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/core/services/api_service.dart';
import 'package:foundation_project/core/storage/managers/sync_data_manager.dart';
import 'package:foundation_project/features/home/data/models/sync_status_entity.dart' as home_sync;

/// Service for synchronization operations
class SyncService {
  final TaskRepository _taskRepository;
  final NoteRepository _noteRepository;
  final ApiService _apiService;
  final SyncDataManager _syncDataManager;
  final Logger _logger;

  SyncService({
    required TaskRepository taskRepository,
    required NoteRepository noteRepository,
    required ApiService apiService,
    required SyncDataManager syncDataManager,
    required Logger logger,
  })  : _taskRepository = taskRepository,
        _noteRepository = noteRepository,
        _apiService = apiService,
        _syncDataManager = syncDataManager,
        _logger = logger;

  /// Get sync status
  Future<AppResult<home_sync.SyncStatusEntity>> getSyncStatus() async {
    try {
      // Get pending sync items (using domain model methods)
      final pendingTasksResult = await _taskRepository.getPendingSyncTasks();
      final pendingNotesResult = await _noteRepository.getPendingSyncNotes();

      if (pendingTasksResult.isFailure || pendingNotesResult.isFailure) {
        return Failure(
          'Failed to get sync status: ${pendingTasksResult.error ?? pendingNotesResult.error}',
          null,
        );
      }

      final pendingTasks = pendingTasksResult.data ?? [];
      final pendingNotes = pendingNotesResult.data ?? [];
      final pendingCount = pendingTasks.length + pendingNotes.length;

      // Get last sync timestamp
      final lastSync = await _syncDataManager.getLastSyncTimestamp();

      // Determine overall status
      final status = _determineStatus(pendingCount, lastSync);

      final syncStatus = home_sync.SyncStatusEntity(
        status: status,
        lastSync: lastSync,
        pendingOperations: pendingCount,
        isSyncing: false,
      );

      return Success(syncStatus);
    } catch (e) {
      _logger.error('Failed to get sync status: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to get sync status: ${e.toString()}', e);
    }
  }

  /// Perform synchronization
  Future<AppResult<void>> sync() async {
    try {
      _logger.info('Starting sync...');

      // Get pending items (using domain model methods)
      final pendingTasksResult = await _taskRepository.getPendingSyncTasks();
      final pendingNotesResult = await _noteRepository.getPendingSyncNotes();

      if (pendingTasksResult.isFailure || pendingNotesResult.isFailure) {
        return Failure(
          'Failed to get pending items: ${pendingTasksResult.error ?? pendingNotesResult.error}',
          null,
        );
      }

      final pendingTasks = pendingTasksResult.data ?? [];
      final pendingNotes = pendingNotesResult.data ?? [];

      // Sync tasks
      if (pendingTasks.isNotEmpty) {
        final result = await _apiService.syncTasks(pendingTasks);
        if (result.isSuccess) {
          final syncedTasks = result.data ?? [];
          for (final task in syncedTasks) {
            await _taskRepository.markAsSynced(
              task.id,
              DateTime.now(),
            );
          }
        } else {
          for (final task in pendingTasks) {
            await _taskRepository.markAsFailed(
              task.id,
              result.error ?? 'Unknown error',
            );
          }
        }
      }

      // Sync notes - using syncTasks for now (mock implementation)
      // In production, this would have a separate syncNotes method
      if (pendingNotes.isNotEmpty) {
        // For now, just mark notes as synced since we don't have syncNotes
        for (final note in pendingNotes) {
          await _noteRepository.markAsSynced(
            note.id,
            DateTime.now(),
          );
        }
      }

      // Update sync timestamp
      await _syncDataManager.setLastSyncTimestamp(DateTime.now());
      await _syncDataManager.setPendingOperationsCount(0);

      _logger.info('Sync completed successfully');
      return const Success(null);
    } catch (e) {
      _logger.error('Sync failed: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Sync failed: ${e.toString()}', e);
    }
  }

  core_sync.SyncStatus _determineStatus(int pendingCount, DateTime? lastSync) {
    if (pendingCount == 0 && lastSync != null) {
      return core_sync.SyncStatus.synced;
    } else if (pendingCount > 0) {
      return core_sync.SyncStatus.pending;
    } else {
      return core_sync.SyncStatus.idle;
    }
  }
}
