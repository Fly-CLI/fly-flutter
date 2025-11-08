import 'package:fly_glow_guard/fly_glow_guard.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:http/http.dart' as http;

/// Mock API service for network operations
class ApiService {
  static const String baseUrl = 'https://api.example.com';
  final http.Client _client;
  final FlyLogger _logger;

  ApiService({
    required FlyLogger logger,
    http.Client? client,
  })  : _logger = logger,
        _client = client ?? http.Client();

  /// Get all tasks (mock)
  Future<AppResult<List<Task>>> getTasks() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock response
      return Success([]);
    } catch (e) {
      _logger.error('Failed to get tasks: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to fetch tasks: ${e.toString()}', e);
    }
  }

  /// Create task (mock)
  Future<AppResult<Task>> createTask(Task task) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - return task with server ID
      return Success(task.copyWith(
        id: 'server_${task.id}',
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      _logger.error('Failed to create task: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to create task: ${e.toString()}', e);
    }
  }

  /// Update task (mock)
  Future<AppResult<Task>> updateTask(Task task) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock response
      return Success(task.copyWith(
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      _logger.error('Failed to update task: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to update task: ${e.toString()}', e);
    }
  }

  /// Delete task (mock)
  Future<AppResult<bool>> deleteTask(String id) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock response
      return Success(true);
    } catch (e) {
      _logger.error('Failed to delete task: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to delete task: ${e.toString()}', e);
    }
  }

  /// Sync tasks (mock)
  Future<AppResult<List<Task>>> syncTasks(List<Task> tasks) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock response - return synced tasks (mark as completed as mock sync)
      return Success(tasks.map((task) => task.copyWith(
        status: TaskStatus.completed,
        updatedAt: DateTime.now(),
      )).toList());
    } catch (e) {
      _logger.error('Failed to sync tasks: ${e.toString()}', stackTrace: StackTrace.current);
      return Failure('Failed to sync tasks: ${e.toString()}', e);
    }
  }
}

