import 'package:drift/drift.dart';
import 'package:foundation_project/core/database/app_database.dart';
import 'package:foundation_project/core/database/tables/tasks_table.dart';

part 'tasks_dao.g.dart';

/// Data Access Object for Tasks table
@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(AppDatabase db) : super(db);

  /// Get all tasks
  Future<List<TaskData>> getAllTasks() {
    return select(tasks).get();
  }

  /// Get task by ID
  Future<TaskData?> getTaskById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert task
  Future<void> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  /// Update task
  Future<bool> updateTask(TasksCompanion task) {
    return update(tasks).replace(task);
  }

  /// Delete task
  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Get tasks by status
  Future<List<TaskData>> getTasksByStatus(String status) {
    return (select(tasks)..where((t) => t.status.equals(status))).get();
  }

  /// Get overdue tasks
  Future<List<TaskData>> getOverdueTasks() {
    final now = DateTime.now();
    return (select(tasks)
          ..where((t) => t.dueDate.isSmallerThanValue(now))
          ..where((t) => t.status.isNotValue('completed')))
        .get();
  }

  /// Get today's tasks
  Future<List<TaskData>> getTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(tasks)
          ..where((t) =>
              t.dueDate.isBetweenValues(startOfDay, endOfDay) |
              (t.dueDate.isNull() & t.status.isNotValue('completed'))))
        .get();
  }

  /// Get pending sync tasks
  Future<List<TaskData>> getPendingSyncTasks() {
    return (select(tasks)
          ..where((t) => t.syncStatus.equals('pending')))
        .get();
  }
}

