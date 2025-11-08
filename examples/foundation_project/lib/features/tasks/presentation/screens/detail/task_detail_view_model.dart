import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/core/foundation/base_view_model.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_view_model.dart';

class TaskDetailViewModelState
    implements FlyViewModelState<TaskDetailViewModelState> {
  const TaskDetailViewModelState({
    required this.isLoading,
    required this.error,
    this.task,
    this.isPerformingAction = false,
    this.hasInitialized = false,
  });

  @override
  final bool isLoading;

  @override
  final String? error;

  final Task? task;
  final bool isPerformingAction;
  final bool hasInitialized;

  @override
  bool get hasError => error != null;

  factory TaskDetailViewModelState.initial() {
    return const TaskDetailViewModelState(
      isLoading: false,
      error: null,
    );
  }

  @override
  TaskDetailViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    Task? task,
    bool clearTask = false,
    bool? isPerformingAction,
    bool? hasInitialized,
  }) {
    return TaskDetailViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      task: clearTask ? null : (task ?? this.task),
      isPerformingAction: isPerformingAction ?? this.isPerformingAction,
      hasInitialized: hasInitialized ?? this.hasInitialized,
    );
  }

  @override
  TaskDetailViewModelState clearError() {
    // ignore: avoid_redundant_argument_values
    return copyWith(error: null, updateError: true);
  }

  @override
  TaskDetailViewModelState withError(String? error) {
    // ignore: avoid_redundant_argument_values
    return copyWith(error: error, updateError: true);
  }

  @override
  TaskDetailViewModelState withLoading(bool isLoading) {
    // ignore: avoid_redundant_argument_values
    return copyWith(isLoading: isLoading);
  }
}

class TaskDetailViewModel extends BaseViewModel<TaskDetailViewModelState> {
  TaskDetailViewModel() : super();

  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);

  @override
  TaskDetailViewModelState build() {
    return TaskDetailViewModelState.initial();
  }

  Future<void> loadTask(String taskId, {bool force = false}) async {
    if (!force &&
        state.hasInitialized &&
        state.task != null &&
        state.task!.id == taskId) {
      return;
    }

    await runAsyncOperation(
      () async {
        final result = await _taskRepository.getTaskById(taskId);
        if (result.isFailure) {
          throw Exception(result.error ?? 'Failed to load task');
        }
        if (result.data == null) {
          ref
              .read(tasksViewModelProvider.notifier)
              .removeTaskFromCache(taskId);
          state = state.copyWith(
            clearTask: true,
            hasInitialized: true,
          );
          return;
        }
        state = state.copyWith(
          task: result.data,
          hasInitialized: true,
        );
      },
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(
          isLoading: isLoading,
          hasInitialized: true,
        );
      },
      errorMessage: 'Failed to load task',
    );
  }

  Future<void> refresh() async {
    final taskId = state.task?.id;
    if (taskId == null) return;
    await loadTask(taskId, force: true);
  }

  Future<void> deleteTask() async {
    final taskId = state.task?.id;
    if (taskId == null) return;
    await runAsyncOperation(
      () async {
        final result = await _taskRepository.deleteTask(taskId);
        if (result.isFailure || result.data != true) {
          throw Exception(result.error ?? 'Failed to delete task');
        }
        ref.read(tasksViewModelProvider.notifier).removeTaskFromCache(taskId);
        state = state.copyWith(clearTask: true);
      },
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isPerformingAction: isLoading);
      },
      errorMessage: 'Failed to delete task',
      successMessage: 'Task deleted',
    );
  }

  Future<void> toggleCompletion() async {
    final task = state.task;
    if (task == null) return;

    final updatedStatus = task.status == TaskStatus.completed
        ? TaskStatus.active
        : TaskStatus.completed;

    final updatedTask = task.copyWith(
      status: updatedStatus,
      updatedAt: DateTime.now(),
    );

    await runAsyncOperation(
      () async {
        final result = await _taskRepository.updateTask(updatedTask);
        if (result.isFailure || result.data == null) {
          throw Exception(result.error ?? 'Failed to update task');
        }
        ref
            .read(tasksViewModelProvider.notifier)
            .replaceTaskInCache(result.data!);
        state = state.copyWith(task: result.data);
      },
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isPerformingAction: isLoading);
      },
      errorMessage: 'Failed to update task',
      successMessage: updatedStatus == TaskStatus.completed
          ? 'Task marked as completed'
          : 'Task marked as active',
    );
  }

  void updateWith(Task task) {
    state = state.copyWith(task: task, hasInitialized: true);
  }
}

final taskDetailViewModelProvider =
    NotifierProvider<TaskDetailViewModel, TaskDetailViewModelState>(
  TaskDetailViewModel.new,
);
