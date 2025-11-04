import 'package:foundation_project/core/models/base/sync_status.dart';
import 'package:foundation_project/core/mappers/base_mapper.dart';
import 'package:foundation_project/features/home/data/models/task_entity.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';

/// Mapper for converting between domain and data models for Task
/// 
/// Extends BaseMapper for reusable mapping functionality.
/// Uses enum extensions for enum/string conversions.
class TaskMapper extends BaseMapper<Task, TaskEntity> {
  /// Singleton instance for instance-based usage
  static final TaskMapper instance = TaskMapper._();

  TaskMapper._();

  @override
  TaskEntity toTarget(Task source, {Map<String, dynamic>? options}) {
    final syncStatus = options?['syncStatus'] as SyncStatus? ?? SyncStatus.pending;
    final lastSyncedAt = options?['lastSyncedAt'] as DateTime?;
    final version = options?['version'] as int? ?? 1;

    return TaskEntity(
      id: source.id,
      title: source.title,
      description: source.description,
      status: source.status.toValue(),
      priority: source.priority.toValue(),
      dueDate: source.dueDate,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      version: version,
    );
  }

  @override
  Task toSource(TaskEntity target, {Map<String, dynamic>? options}) {
    return Task(
      id: target.id,
      title: target.title,
      description: target.description,
      status: taskStatusFromString(target.status),
      priority: taskPriorityFromString(target.priority),
      dueDate: target.dueDate,
      createdAt: target.createdAt,
      updatedAt: target.updatedAt,
    );
  }
}

