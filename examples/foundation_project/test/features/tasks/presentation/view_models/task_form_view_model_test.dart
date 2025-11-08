import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/form/task_form_view_model.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_view_model.dart';
import 'package:fly_glow_guard/fly_glow_guard.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class StubTasksViewModel extends TasksViewModel {
  StubTasksViewModel();

  Task? insertedTask;
  Task? replacedTask;

  @override
  TasksViewModelState build() {
    return TasksViewModelState.initial();
  }

  @override
  void insertTaskIntoCache(Task task) {
    insertedTask = task;
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
}

Task _buildTask({
  String id = 'task-1',
  String title = 'My Task',
  TaskStatus status = TaskStatus.active,
  TaskPriority priority = TaskPriority.medium,
}) {
  final now = DateTime.now();
  return Task(
    id: id,
    title: title,
    description: 'Description for $id',
    status: status,
    priority: priority,
    dueDate: now.add(const Duration(days: 3)),
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

  group('TaskFormViewModel', () {
    test('initialize seeds state from existing task', () {
      final task = _buildTask();
      final viewModel = container.read(taskFormViewModelProvider.notifier);

      viewModel.initialize(task);
      final state = container.read(taskFormViewModelProvider);

      expect(state.title, task.title);
      expect(state.description, task.description ?? '');
      expect(state.priority, task.priority);
      expect(state.status, task.status);
      expect(state.dueDate, task.dueDate);
    });

    test('submit creates new task when not editing', () async {
      when(() => repository.createTask(any())).thenAnswer((invocation) async {
        final task = invocation.positionalArguments.first as Task;
        return Success(task);
      });

      final viewModel = container.read(taskFormViewModelProvider.notifier);
      viewModel.updateTitle('New Task');
      viewModel.updateDescription('New description');
      viewModel.updatePriority(TaskPriority.high);
      viewModel.updateStatus(TaskStatus.active);

      final result = await viewModel.submit();

      expect(result, isNotNull);
      expect(stubTasksViewModel.insertedTask, equals(result));
      verify(() => repository.createTask(any())).called(1);
    });

    test('submit updates existing task when in edit mode', () async {
      final existing = _buildTask();
      final updated = existing.copyWith(
        title: 'Updated Title',
        updatedAt: existing.updatedAt.add(const Duration(minutes: 2)),
      );

      when(() => repository.updateTask(any()))
          .thenAnswer((_) async => Success(updated));

      final viewModel = container.read(taskFormViewModelProvider.notifier);
      viewModel.initialize(existing);
      viewModel.updateTitle('Updated Title');

      final result = await viewModel.submit();

      expect(result?.title, 'Updated Title');
      expect(stubTasksViewModel.replacedTask?.title, 'Updated Title');
      verify(() => repository.updateTask(any())).called(1);
    });

    test('submit returns null when validation fails', () async {
      final viewModel = container.read(taskFormViewModelProvider.notifier);
      viewModel.updateTitle('   ');

      final result = await viewModel.submit();

      expect(result, isNull);
      final state = container.read(taskFormViewModelProvider);
      expect(
        state.fieldErrors[TaskFormField.title],
        TaskFormFieldError.emptyTitle,
      );
      verifyNever(() => repository.createTask(any()));
      verifyNever(() => repository.updateTask(any()));
    });
  });
}
