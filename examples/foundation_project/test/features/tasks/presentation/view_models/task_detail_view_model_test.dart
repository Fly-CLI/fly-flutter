import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/detail/task_detail_view_model.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_view_model.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class StubTasksViewModel extends TasksViewModel {
  StubTasksViewModel();

  final List<String> removedTaskIds = <String>[];
  Task? replacedTask;

  @override
  TasksViewModelState build() {
    return TasksViewModelState.initial();
  }

  @override
  void removeTaskFromCache(String taskId) {
    removedTaskIds.add(taskId);
  }

  @override
  void replaceTaskInCache(Task task) {
    replacedTask = task;
  }

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> applySearch(String query) async {}

  @override
  Future<void> clearSearch() async {}

  @override
  Future<void> applyStatusFilter(TaskStatus? status) async {}

  @override
  void toggleTaskSelection(String taskId) {}

  @override
  void clearSelection() {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<void> deleteSelectedTasks() async {}

  @override
  Future<void> toggleComplete(String taskId) async {}

  @override
  Future<void> upsertTask(Task task) async {}

  @override
  void insertTaskIntoCache(Task task) {}
}

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
    dueDate: now.add(const Duration(days: 2)),
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_buildTask());
  });

  late MockTaskRepository repository;
  late StubTasksViewModel stubTasksViewModel;
  late ProviderContainer container;

  setUp(() {
    repository = MockTaskRepository();
    stubTasksViewModel = StubTasksViewModel();
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        tasksViewModelProvider.overrideWith(() => stubTasksViewModel),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TaskDetailViewModel', () {
    test('loadTask hydrates state from repository', () async {
      final task = _buildTask();
      when(() => repository.getTaskById(task.id)).thenAnswer(
        (_) async => Success(task),
      );

      final viewModel = container.read(taskDetailViewModelProvider.notifier);

      await viewModel.loadTask(task.id);

      final state = container.read(taskDetailViewModelProvider);
      expect(state.task, equals(task));
      verify(() => repository.getTaskById(task.id)).called(1);
    });

    test('deleteTask clears state and notifies tasks view model', () async {
      final task = _buildTask();
      when(() => repository.deleteTask(task.id)).thenAnswer(
        (_) async => Success(true),
      );

      final viewModel = container.read(taskDetailViewModelProvider.notifier);
      viewModel.state = viewModel.state.copyWith(task: task);

      await viewModel.deleteTask();

      final state = container.read(taskDetailViewModelProvider);
      expect(state.task, isNull);
      expect(stubTasksViewModel.removedTaskIds, contains(task.id));
      verify(() => repository.deleteTask(task.id)).called(1);
    });

    test('toggleCompletion updates repository and tasks list cache', () async {
      final task = _buildTask(status: TaskStatus.active);
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        updatedAt: task.updatedAt.add(const Duration(minutes: 5)),
      );

      when(() => repository.updateTask(any())).thenAnswer(
        (_) async => Success(updatedTask),
      );

      final viewModel = container.read(taskDetailViewModelProvider.notifier);
      viewModel.state = viewModel.state.copyWith(task: task);

      await viewModel.toggleCompletion();

      final state = container.read(taskDetailViewModelProvider);
      expect(state.task?.status, TaskStatus.completed);
      expect(stubTasksViewModel.replacedTask, equals(updatedTask));
      verify(() => repository.updateTask(any())).called(1);
    });
  });
}
