import 'package:fly_flow_guard/fly_flow_guard.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:foundation_project/core/pagination/paginated_result.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';

/// Pagination service for tasks
class TaskPaginationService {
  final TaskRepository _taskRepository;
  final FlyLogger _logger;

  TaskPaginationService(
    this._taskRepository, {
    required FlyLogger logger,
  }) : _logger = logger;

  /// Get paginated tasks
  Future<AppResult<PaginatedResult<Task>>> getPaginated({
    required int page,
    required int pageSize,
    String? searchQuery,
    TaskStatus? statusFilter,
  }) async {
    try {
      // Get all tasks or filtered tasks
      final tasksResult = searchQuery != null
          ? await _taskRepository.searchTasks(searchQuery)
          : statusFilter != null
              ? await _taskRepository.getTasksByStatus(_statusToString(statusFilter))
              : await _taskRepository.getAllTasks();

      if (tasksResult.isFailure) {
        return Failure(
          'Failed to get tasks: ${tasksResult.error}',
          tasksResult.data,
        );
      }

      final allTasks = tasksResult.data ?? [];

      // Calculate pagination
      final total = allTasks.length;
      final start = page * pageSize;
      final end = (start + pageSize).clamp(0, total);
      final paginatedTasks = allTasks.sublist(
        start.clamp(0, total),
        end,
      );

      final result = PaginatedResult<Task>.fromItems(
        items: paginatedTasks,
        total: total,
        page: page,
        pageSize: pageSize,
      );

      return Success(result);
    } catch (e) {
      _logger.error('Failed to get paginated tasks: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to get paginated tasks: ${e.toString()}', e);
    }
  }

  /// Convert TaskStatus enum to string for repository
  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.active:
        return 'active';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.overdue:
        return 'overdue';
    }
  }
}

