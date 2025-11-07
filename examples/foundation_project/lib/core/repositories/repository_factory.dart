import 'package:foundation_project/core/database/app_database.dart';
import 'package:foundation_project/foundation/logger/fly_logger.dart';
import 'package:foundation_project/core/repositories/note_repository.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';

/// Repository factory for centralized repository creation
/// Provides lazy initialization and centralized access to all repositories
class RepositoryFactory {
  final AppDatabase _database;
  final Map<String, dynamic> _repositories = {};
  final Logger _logger;

  RepositoryFactory(
    this._database, {
    required Logger logger,
  }) : _logger = logger;

  /// Get task repository
  TaskRepository get taskRepository =>
      _getRepository<TaskRepository>('task');

  /// Get note repository
  NoteRepository get noteRepository =>
      _getRepository<NoteRepository>('note');

  /// Get repository with lazy initialization
  T _getRepository<T>(String key) {
    if (!_repositories.containsKey(key)) {
      _repositories[key] = _createRepository<T>(key);
      _logger.debug('Created repository: $key');
    }
    return _repositories[key] as T;
  }

  /// Create repository instance based on key
  dynamic _createRepository<T>(String key) {
    switch (key) {
      case 'task':
        return TaskRepository(_database);
      case 'note':
        return NoteRepository(_database);
      default:
        throw ArgumentError('Unknown repository type: $key');
    }
  }

  /// Clear all repositories (useful for testing)
  void clearRepositories() {
    _repositories.clear();
    _logger.debug('Cleared all repositories');
  }
}

