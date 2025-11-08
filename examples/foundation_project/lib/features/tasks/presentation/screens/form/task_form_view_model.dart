import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/core/foundation/base_view_model.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';
import 'package:foundation_project/features/tasks/presentation/screens/list/tasks_view_model.dart';
import 'package:uuid/uuid.dart';

enum TaskFormField {
  title,
  description,
  dueDate,
}

enum TaskFormFieldError {
  emptyTitle,
  dueDateInPast,
}

class TaskFormViewModelState
    implements FlyViewModelState<TaskFormViewModelState> {
  const TaskFormViewModelState({
    required this.isLoading,
    required this.error,
    required this.isSaving,
    required this.initialTask,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.fieldErrors,
    required this.hasInitialized,
    required this.isDirty,
  });

  @override
  final bool isLoading;

  @override
  final String? error;

  final bool isSaving;
  final Task? initialTask;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final Map<TaskFormField, TaskFormFieldError> fieldErrors;
  final bool hasInitialized;
  final bool isDirty;

  @override
  bool get hasError => error != null;

  factory TaskFormViewModelState.initial() {
    return const TaskFormViewModelState(
      isLoading: false,
      error: null,
      isSaving: false,
      initialTask: null,
      title: '',
      description: '',
      priority: TaskPriority.medium,
      status: TaskStatus.active,
      dueDate: null,
      fieldErrors: <TaskFormField, TaskFormFieldError>{},
      hasInitialized: false,
      isDirty: false,
    );
  }

  bool get isEditMode => initialTask != null;

  @override
  TaskFormViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    bool? isSaving,
    Task? initialTask,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    Map<TaskFormField, TaskFormFieldError>? fieldErrors,
    bool? hasInitialized,
    bool? isDirty,
  }) {
    return TaskFormViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      isSaving: isSaving ?? this.isSaving,
      initialTask: initialTask ?? this.initialTask,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  TaskFormViewModelState clearError() {
    // ignore: avoid_redundant_argument_values
    return copyWith(error: null, updateError: true);
  }

  @override
  TaskFormViewModelState withError(String? error) {
    // ignore: avoid_redundant_argument_values
    return copyWith(error: error, updateError: true);
  }

  @override
  TaskFormViewModelState withLoading(bool isLoading) {
    // ignore: avoid_redundant_argument_values
    return copyWith(isLoading: isLoading);
  }
}

class TaskFormViewModel extends BaseViewModel<TaskFormViewModelState> {
  TaskFormViewModel() : super();

  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);
  final Uuid _uuid = const Uuid();

  @override
  TaskFormViewModelState build() {
    return TaskFormViewModelState.initial();
  }

  void initialize(Task? task) {
    if (state.hasInitialized) return;
    if (task == null) {
      state = state.copyWith(hasInitialized: true);
      return;
    }
    state = state.copyWith(
      initialTask: task,
      title: task.title,
      description: task.description ?? '',
      priority: task.priority,
      status: task.status,
      dueDate: task.dueDate,
      hasInitialized: true,
    );
  }

  void updateTitle(String value) {
    state = state.copyWith(
      title: value,
      isDirty: true,
      fieldErrors: _removeFieldError(TaskFormField.title),
    );
  }

  void updateDescription(String value) {
    state = state.copyWith(
      description: value,
      isDirty: true,
    );
  }

  void updatePriority(TaskPriority priority) {
    state = state.copyWith(
      priority: priority,
      isDirty: true,
    );
  }

  void updateStatus(TaskStatus status) {
    state = state.copyWith(
      status: status,
      isDirty: true,
    );
  }

  void updateDueDate(DateTime? dueDate) {
    state = state.copyWith(
      dueDate: dueDate,
      clearDueDate: dueDate == null,
      isDirty: true,
      fieldErrors: _removeFieldError(TaskFormField.dueDate),
    );
  }

  Map<TaskFormField, TaskFormFieldError> _validate() {
    final errors = <TaskFormField, TaskFormFieldError>{};
    if (state.title.trim().isEmpty) {
      errors[TaskFormField.title] = TaskFormFieldError.emptyTitle;
    }
    if (state.dueDate != null) {
      final now = DateTime.now();
      final normalizedNow = DateTime(now.year, now.month, now.day);
      if (state.dueDate!.isBefore(normalizedNow)) {
        errors[TaskFormField.dueDate] = TaskFormFieldError.dueDateInPast;
      }
    }
    return errors;
  }

  Future<Task?> submit() async {
    final validationErrors = _validate();
    if (validationErrors.isNotEmpty) {
      state = state.copyWith(fieldErrors: validationErrors);
      return null;
    }

    final now = DateTime.now();
    final trimmedTitle = state.title.trim();
    final trimmedDescription = state.description.trim();

    final task = state.initialTask?.copyWith(
          title: trimmedTitle,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          priority: state.priority,
          status: state.status,
          dueDate: state.dueDate,
          updatedAt: now,
        ) ??
        Task(
          id: _uuid.v4(),
          title: trimmedTitle,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          priority: state.priority,
          status: state.status,
          dueDate: state.dueDate,
          createdAt: now,
          updatedAt: now,
        );

    Task? savedTask;

    await runAsyncOperation(
      () async {
        final result = state.isEditMode
            ? await _taskRepository.updateTask(task)
            : await _taskRepository.createTask(task);
        if (result.isFailure || result.data == null) {
          throw Exception(result.error ?? 'Failed to save task');
        }
        savedTask = result.data!;
        if (state.isEditMode) {
          ref
              .read(tasksViewModelProvider.notifier)
              .replaceTaskInCache(savedTask!);
        } else {
          ref
              .read(tasksViewModelProvider.notifier)
              .insertTaskIntoCache(savedTask!);
        }
        state = state.copyWith(
          initialTask: savedTask,
          isDirty: false,
          fieldErrors: const <TaskFormField, TaskFormFieldError>{},
        );
      },
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isSaving: isLoading);
      },
      errorMessage: 'Failed to save task',
      successMessage: 'Task saved',
    );

    return savedTask;
  }

  Map<TaskFormField, TaskFormFieldError> _removeFieldError(
    TaskFormField field,
  ) {
    if (!state.fieldErrors.containsKey(field)) {
      return state.fieldErrors;
    }
    final updated =
        Map<TaskFormField, TaskFormFieldError>.from(state.fieldErrors)
          ..remove(field);
    return updated;
  }
}

final taskFormViewModelProvider =
    NotifierProvider<TaskFormViewModel, TaskFormViewModelState>(
  TaskFormViewModel.new,
);
