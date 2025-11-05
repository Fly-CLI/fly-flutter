import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:foundation_project/core/models/sync_status.dart';
import 'package:foundation_project/features/home/data/models/note_entity.dart';
import 'package:foundation_project/features/home/data/models/task_entity.dart';
import 'package:foundation_project/features/home/domain/models/note.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/home/mappers/home_mappr.auto_mappr.dart';

/// AutoMappr configuration for the home feature
/// 
/// Handles mapping between domain models and data entities:
/// - Task ↔ TaskEntity
/// - Note ↔ NoteEntity
/// 
/// Enum conversions are handled via TypeConverter:
/// - TaskStatus ↔ String
/// - TaskPriority ↔ String
@AutoMappr([
  MapType<Task, TaskEntity>(
    fields: [
      Field('status', custom: HomeMappr.taskStatusToString),
      Field('priority', custom: HomeMappr.taskPriorityToString),
      Field('syncStatus', custom: HomeMappr.defaultSyncStatus),
      Field('version', custom: HomeMappr.defaultVersion),
    ],
  ),
  MapType<TaskEntity, Task>(
    fields: [
      Field('status', custom: HomeMappr.stringToTaskStatus),
      Field('priority', custom: HomeMappr.stringToTaskPriority),
    ],
  ),
  MapType<Note, NoteEntity>(
    fields: [
      Field('syncStatus', custom: HomeMappr.defaultSyncStatusNote),
      Field('version', custom: HomeMappr.defaultVersionNote),
    ],
  ),
  MapType<NoteEntity, Note>(),
])
class HomeMappr extends $HomeMappr {
  /// Convert TaskStatus enum to string
  /// Used for Task -> TaskEntity mapping
  static String taskStatusToString(Task task) {
    return task.status.toValue();
  }

  /// Convert string to TaskStatus enum
  /// Used for TaskEntity -> Task mapping (reverse)
  static TaskStatus stringToTaskStatus(TaskEntity entity) {
    return taskStatusFromString(entity.status);
  }

  /// Convert TaskPriority enum to string
  /// Used for Task -> TaskEntity mapping
  static String taskPriorityToString(Task task) {
    return task.priority.toValue();
  }

  /// Convert string to TaskPriority enum
  /// Used for TaskEntity -> Task mapping (reverse)
  static TaskPriority stringToTaskPriority(TaskEntity entity) {
    return taskPriorityFromString(entity.priority);
  }

  /// Default sync status for entity mapping
  static SyncStatus defaultSyncStatus(Task source) {
    return SyncStatus.pending;
  }

  /// Default version for entity mapping
  static int defaultVersion(Task source) {
    return 1;
  }

  /// Default sync status for entity mapping (Note)
  static SyncStatus defaultSyncStatusNote(Note source) {
    return SyncStatus.pending;
  }

  /// Default version for entity mapping (Note)
  static int defaultVersionNote(Note source) {
    return 1;
  }
}

