import 'package:foundation_project/core/foundation/operations/result.dart';
import 'package:foundation_project/core/foundation/utils/app_logger.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/core/services/cache_service.dart';
import 'package:foundation_project/features/home/data/models/statistics_entity.dart';

/// Service for calculating statistics
class StatisticsService {
  final TaskRepository _taskRepository;
  final CacheService _cacheService;
  final Logger _logger;

  StatisticsService({
    required TaskRepository taskRepository,
    required CacheService cacheService,
    required Logger logger,
  })  : _taskRepository = taskRepository,
        _cacheService = cacheService,
        _logger = logger;

  /// Get statistics with caching
  Future<AppResult<StatisticsEntity>> getStatistics() async {
    try {
      // Check cache first
      const cacheKey = 'statistics';
      final cached = _cacheService.get<StatisticsEntity>(cacheKey);
      if (cached != null) {
        _logger.debug('Returning cached statistics');
        return Success(cached);
      }

      // Get all tasks
      final tasksResult = await _taskRepository.getAllTasks();
      if (tasksResult.isFailure) {
        return Failure(
          'Failed to get tasks: ${tasksResult.error}',
          tasksResult.data,
        );
      }

      final tasks = tasksResult.data ?? [];

      // Calculate statistics
      final totalTasks = tasks.length;
      final completedTasks =
          tasks.where((task) => task.isCompleted).length;
      final overdueTasks = tasks.where((task) {
        if (task.dueDate == null) return false;
        return task.isOverdue;
      }).length;
      final todayTasks = tasks.where((task) {
        if (task.dueDate == null) return false;
        return task.isDueToday && !task.isCompleted;
      }).length;

      final statistics = StatisticsEntity(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        overdueTasks: overdueTasks,
        todayTasks: todayTasks,
      );

      // Cache the result
      _cacheService.set(cacheKey, statistics);

      return Success(statistics);
    } catch (e) {
      _logger.error('Failed to get statistics: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to get statistics: ${e.toString()}', e);
    }
  }

  /// Refresh statistics (clear cache and recalculate)
  Future<AppResult<StatisticsEntity>> refreshStatistics() async {
    _cacheService.remove('statistics');
    return getStatistics();
  }
}
