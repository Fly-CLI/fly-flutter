import 'package:drift/drift.dart';
import 'package:foundation_project/core/database/app_database.dart';
import 'package:foundation_project/core/database/daos/tasks_dao.dart';
import 'package:fly_operations/fly_operations.dart';
import 'package:foundation_project/core/models/sync_status.dart';
import 'package:foundation_project/core/repositories/base/base_repository.dart';
import 'package:foundation_project/features/home/mappers/home_mappr.dart';
import 'package:foundation_project/features/home/data/models/task_entity.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';

/// Task repository implementation
/// Works with domain Task models internally, but uses TaskEntity for persistence
class TaskRepository extends BaseRepository<TaskEntity> {
  final AppDatabase _database;
  late final TasksDao _dao;
  final HomeMappr _mappr = HomeMappr();

  TaskRepository(this._database) : _dao = TasksDao(_database), super(
        tableName: 'tasks',
        fromMap: (map) => TaskEntity.fromMap(map),
        toMap: (task) => task.toMap(),
      );

  // =========================================================================
  // DOMAIN MODEL METHODS (Public API - returns domain models)
  // =========================================================================

  /// Get all tasks as domain models
  /// Note: This method returns domain models, not entities
  Future<AppResult<List<Task>>> getAllTasks() async {
    try {
      final tasksData = await _dao.getAllTasks();
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      final domainTasks = _mappr.convertList<TaskEntity, Task>(entities);
      return Success(domainTasks);
    } catch (e) {
      return Failure('Failed to getAllTasks: ${e.toString()}', e);
    }
  }

  /// Get task by ID as domain model
  Future<AppResult<Task?>> getTaskById(String id) async {
    try {
      final taskData = await _dao.getTaskById(id);
      if (taskData == null) return Success(null);
      final entity = _mapTaskDataToEntity(taskData);
      final domainTask = _mappr.convert<TaskEntity, Task>(entity);
      return Success(domainTask);
    } catch (e) {
      return Failure('Failed to getTaskById: ${e.toString()}', e);
    }
  }

  // =========================================================================
  // INTERFACE METHODS (Required by IBaseRepository - returns entities)
  // =========================================================================

  @override
  Future<AppResult<List<TaskEntity>>> getAll() async {
    try {
      final tasksData = await _dao.getAllTasks();
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      return Success(entities);
    } catch (e) {
      return handleListError(e, 'getAll');
    }
  }

  @override
  Future<AppResult<TaskEntity?>> getById(String id) async {
    try {
      final taskData = await _dao.getTaskById(id);
      if (taskData == null) return Success(null);
      final entity = _mapTaskDataToEntity(taskData);
      return Success(entity);
    } catch (e) {
      return handleError(e, 'getById');
    }
  }

  @override
  Future<AppResult<TaskEntity>> create(TaskEntity entity) async {
    return await super.create(entity);
  }

  /// Create task from domain model
  Future<AppResult<Task>> createTask(Task task) async {
    final entity = _mappr.convert<Task, TaskEntity>(task);
    final result = await super.create(entity);
    if (result.isFailure) {
      final originalError = result is Failure<TaskEntity> ? result.originalError : null;
      return Failure(result.error!, originalError);
    }
    return Success(_mappr.convert<TaskEntity, Task>(result.data!));
  }

  @override
  Future<AppResult<TaskEntity>> performCreate(TaskEntity entity) async {
    try {
      final validation = validateEntity(entity);
      if (validation.isFailure) return validation;

      final taskData = _mapEntityToTaskData(entity);
      await _dao.insertTask(taskData);
      return Success(entity);
    } catch (e) {
      return handleError(e, 'create');
    }
  }

  @override
  Future<AppResult<TaskEntity>> update(TaskEntity entity) async {
    return await super.update(entity);
  }

  /// Update task from domain model
  Future<AppResult<Task>> updateTask(Task task) async {
    final entity = _mappr.convert<Task, TaskEntity>(task).copyWith(
      syncStatus: SyncStatus.pending,
    );
    final result = await super.update(entity);
    if (result.isFailure) {
      final originalError = result is Failure<TaskEntity> ? result.originalError : null;
      return Failure(result.error!, originalError);
    }
    return Success(_mappr.convert<TaskEntity, Task>(result.data!));
  }

  @override
  Future<AppResult<TaskEntity>> performUpdate(TaskEntity entity) async {
    try {
      final validation = validateEntity(entity);
      if (validation.isFailure) return validation;

      final taskData = _mapEntityToTaskData(entity.copyWith(
        updatedAt: DateTime.now(),
      ));
      await _dao.updateTask(taskData);
      return Success(entity.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      return handleError(e, 'update');
    }
  }

  /// Delete task by ID (domain model API)
  Future<AppResult<bool>> deleteTask(String id) async {
    return await super.delete(id);
  }

  @override
  Future<AppResult<bool>> performDelete(String id) async {
    try {
      final count = await _dao.deleteTask(id);
      return Success(count > 0);
    } catch (e) {
      return handleBooleanError(e, 'delete');
    }
  }

  @override
  Future<AppResult<List<TaskEntity>>> search(String query) async {
    try {
      final allTasks = await _dao.getAllTasks();
      final filtered = allTasks
          .where((task) {
            final titleMatch = task.title.toLowerCase().contains(query.toLowerCase());
            final descMatch = task.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
            return titleMatch || descMatch;
          })
          .toList();
      final entities = filtered.map((data) => _mapTaskDataToEntity(data)).toList();
      return Success(entities);
    } catch (e) {
      return handleListError(e, 'search');
    }
  }

  /// Search tasks by query (domain model API)
  Future<AppResult<List<Task>>> searchTasks(String query) async {
    try {
      final allTasks = await _dao.getAllTasks();
      final filtered = allTasks
          .where((task) {
            final titleMatch = task.title.toLowerCase().contains(query.toLowerCase());
            final descMatch = task.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
            return titleMatch || descMatch;
          })
          .toList();
      final entities = filtered.map((data) => _mapTaskDataToEntity(data)).toList();
      final domainTasks = _mappr.convertList<TaskEntity, Task>(entities);
      return Success(domainTasks);
    } catch (e) {
      return Failure('Failed to searchTasks: ${e.toString()}', e);
    }
  }

  @override
  Future<AppResult<List<TaskEntity>>> getPendingSync() async {
    try {
      final tasksData = await _dao.getPendingSyncTasks();
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      return Success(entities);
    } catch (e) {
      return handleListError(e, 'getPendingSync');
    }
  }

  /// Get tasks that need synchronization (domain model API)
  Future<AppResult<List<Task>>> getPendingSyncTasks() async {
    try {
      final tasksData = await _dao.getPendingSyncTasks();
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      final domainTasks = _mappr.convertList<TaskEntity, Task>(entities);
      return Success(domainTasks);
    } catch (e) {
      return Failure('Failed to getPendingSyncTasks: ${e.toString()}', e);
    }
  }

  @override
  Future<AppResult<void>> markAsSynced(String id, DateTime syncedAt) async {
    try {
      final entityResult = await getById(id);
      if (entityResult.isFailure || entityResult.data == null) {
        return Failure('Task not found');
      }

      final entity = entityResult.data!;
      final updatedEntity = entity.markAsSynced() as TaskEntity;
      await performUpdate(updatedEntity);
      return Success(null);
    } catch (e) {
      return handleVoidError(e, 'markAsSynced');
    }
  }

  @override
  Future<AppResult<void>> markAsConflicted(String id) async {
    try {
      final entityResult = await getById(id);
      if (entityResult.isFailure || entityResult.data == null) {
        return Failure('Task not found');
      }

      final entity = entityResult.data!;
      final updatedEntity = entity.markAsConflicted() as TaskEntity;
      await performUpdate(updatedEntity);
      return Success(null);
    } catch (e) {
      return handleVoidError(e, 'markAsConflicted');
    }
  }

  @override
  Future<AppResult<void>> markAsFailed(String id, String errorMessage) async {
    try {
      final entityResult = await getById(id);
      if (entityResult.isFailure || entityResult.data == null) {
        return Failure('Task not found');
      }

      final entity = entityResult.data!;
      final updatedEntity = entity.markAsFailed() as TaskEntity;
      await performUpdate(updatedEntity);
      return Success(null);
    } catch (e) {
      return handleVoidError(e, 'markAsFailed');
    }
  }

  /// Get tasks by status (domain model API)
  Future<AppResult<List<Task>>> getTasksByStatus(String status) async {
    try {
      final tasksData = await _dao.getTasksByStatus(status);
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      final domainTasks = _mappr.convertList<TaskEntity, Task>(entities);
      return Success(domainTasks);
    } catch (e) {
      return Failure('Failed to getTasksByStatus: ${e.toString()}', e);
    }
  }

  /// Get overdue tasks
  Future<AppResult<List<Task>>> getOverdueTasks() async {
    try {
      final tasksData = await _dao.getOverdueTasks();
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      final domainTasks = _mappr.convertList<TaskEntity, Task>(entities);
      return Success(domainTasks);
    } catch (e) {
      return Failure('Failed to getOverdueTasks: ${e.toString()}', e);
    }
  }

  /// Get today's tasks
  Future<AppResult<List<Task>>> getTodayTasks() async {
    try {
      final tasksData = await _dao.getTodayTasks();
      final entities = tasksData.map((data) => _mapTaskDataToEntity(data)).toList();
      final domainTasks = _mappr.convertList<TaskEntity, Task>(entities);
      return Success(domainTasks);
    } catch (e) {
      return Failure('Failed to getTodayTasks: ${e.toString()}', e);
    }
  }

  /// Map TaskData to TaskEntity
  TaskEntity _mapTaskDataToEntity(TaskData data) {
    return TaskEntity.fromMap({
      'id': data.id,
      'title': data.title,
      'description': data.description,
      'status': data.status,
      'priority': data.priority,
      'due_date': data.dueDate?.toIso8601String(),
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': data.updatedAt.toIso8601String(),
      'sync_status': data.syncStatus,
      'last_synced_at': data.lastSyncedAt?.toIso8601String(),
      'version': data.version,
    });
  }

  /// Map TaskEntity to TasksCompanion
  TasksCompanion _mapEntityToTaskData(TaskEntity entity) {
    return TasksCompanion.insert(
      id: entity.id,
      title: entity.title,
      description: Value(entity.description),
      status: entity.status,
      priority: entity.priority,
      dueDate: Value(entity.dueDate),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      syncStatus: Value(entity.syncStatus.name),
      lastSyncedAt: Value(entity.lastSyncedAt),
      version: Value(entity.version),
    );
  }
}

