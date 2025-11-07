import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/database/app_database.dart';
import 'package:foundation_project/core/repositories/note_repository.dart';
import 'package:foundation_project/core/repositories/repository_factory.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/core/providers/logger_provider.dart';

/// Provider for database
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for repository factory
final repositoryFactoryProvider = Provider<RepositoryFactory>((ref) {
  return RepositoryFactory(
    ref.watch(databaseProvider),
    logger: ref.watch(loggerProvider('RepositoryFactory')),
  );
});

/// Provider for task repository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return ref.watch(repositoryFactoryProvider).taskRepository;
});

/// Provider for note repository
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return ref.watch(repositoryFactoryProvider).noteRepository;
});

