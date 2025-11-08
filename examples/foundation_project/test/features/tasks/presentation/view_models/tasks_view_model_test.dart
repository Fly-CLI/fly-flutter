import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/pagination/paginated_result.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/providers/service_providers.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/core/services/pagination/task_pagination_service.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_view_model.dart';
import 'package:fly_glow_guard/fly_glow_guard.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockTaskPaginationService extends Mock implements TaskPaginationService {}

Task _buildTask({
  String id = 'task-1',
  TaskStatus status = TaskStatus.active,
}) {
  final now = DateTime.now();
  return Task(
    id: id,
    title: 'Task $id',
    description: 'Description for $id',
    status: status,
    priority: TaskPriority.medium,
    dueDate: now.add(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_buildTask());
  });

  late MockTaskRepository repository;
  late MockTaskPaginationService paginationService;
  late ProviderContainer container;

  setUp(() {
    repository = MockTaskRepository();
    paginationService = MockTaskPaginationService();
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        taskPaginationServiceProvider.overrideWithValue(paginationService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TasksViewModel', () {
    test('loadInitial populates tasks from pagination service', () async {
      final tasks = [
        _buildTask(id: 'task-1'),
        _buildTask(id: 'task-2'),
      ];

      when(
        () => paginationService.getPaginated(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          searchQuery: any(named: 'searchQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer(
        (_) async => Success(
          PaginatedResult.fromItems(
            items: tasks,
            total: tasks.length,
          ),
        ),
      );

      final viewModel = container.read(tasksViewModelProvider.notifier);

      await viewModel.loadInitial();

      final state = container.read(tasksViewModelProvider);
      expect(state.pagination.items, tasks);
      expect(state.isLoading, isFalse);
      verify(
        () => paginationService.getPaginated(
          page: 0,
          pageSize: any(named: 'pageSize'),
          searchQuery: null,
          statusFilter: null,
        ),
      ).called(1);
    });

    test('deleteTask removes task from state when repository succeeds',
        () async {
      final existingTasks = [
        _buildTask(id: 'task-1'),
        _buildTask(id: 'task-2'),
      ];

      when(() => repository.deleteTask('task-1')).thenAnswer(
        (_) async => Success(true),
      );

      final viewModel = container.read(tasksViewModelProvider.notifier);
      viewModel.state = viewModel.state.copyWith(
        pagination: PaginatedResult.fromItems(
          items: existingTasks,
          total: existingTasks.length,
        ),
      );

      await viewModel.deleteTask('task-1');

      final state = container.read(tasksViewModelProvider);
      expect(state.pagination.items.map((task) => task.id), ['task-2']);
      verify(() => repository.deleteTask('task-1')).called(1);
    });

    test('toggleComplete updates task status via repository', () async {
      final task = _buildTask(id: 'task-1', status: TaskStatus.active);
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        updatedAt: task.updatedAt.add(const Duration(minutes: 1)),
      );

      when(() => repository.updateTask(any())).thenAnswer(
        (_) async => Success(updatedTask),
      );

      final viewModel = container.read(tasksViewModelProvider.notifier);
      viewModel.state = viewModel.state.copyWith(
        pagination: PaginatedResult.fromItems(items: [task], total: 1),
      );

      await viewModel.toggleComplete(task.id);

      final state = container.read(tasksViewModelProvider);
      expect(state.pagination.items.single.status, TaskStatus.completed);
      verify(() => repository.updateTask(any())).called(1);
    });
  });
}
