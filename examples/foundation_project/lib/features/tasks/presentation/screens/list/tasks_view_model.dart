import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/core/foundation/base_view_model.dart';
import 'package:foundation_project/core/pagination/paginated_result.dart';
import 'package:foundation_project/core/providers/repository_providers.dart';
import 'package:foundation_project/core/providers/service_providers.dart';
import 'package:foundation_project/core/repositories/task_repository.dart';
import 'package:foundation_project/core/services/pagination/task_pagination_service.dart';
import 'package:foundation_project/features/home/domain/models/task.dart';

const _defaultPageSize = 20;

class TasksViewModelState implements FlyViewModelState<TasksViewModelState> {
  const TasksViewModelState({
    required this.isLoading,
    required this.error,
    required this.pagination,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.selectedTaskIds = const <String>{},
    this.searchQuery = '',
    this.statusFilter,
  });

  @override
  final bool isLoading;

  @override
  final String? error;

  final PaginatedResult<Task> pagination;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Set<String> selectedTaskIds;
  final String searchQuery;
  final TaskStatus? statusFilter;

  @override
  bool get hasError => error != null;

  factory TasksViewModelState.initial() {
    return TasksViewModelState(
      isLoading: false,
      error: null,
      pagination: PaginatedResult<Task>.empty(),
    );
  }

  bool get isInitialLoading => isLoading && pagination.items.isEmpty;

  bool get hasSelection => selectedTaskIds.isNotEmpty;

  bool isTaskSelected(String taskId) => selectedTaskIds.contains(taskId);

  @override
  TasksViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    PaginatedResult<Task>? pagination,
    bool? isRefreshing,
    bool? isLoadingMore,
    Set<String>? selectedTaskIds,
    bool clearSelection = false,
    String? searchQuery,
    TaskStatus? statusFilter,
  }) {
    return TasksViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      pagination: pagination ?? this.pagination,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedTaskIds: clearSelection
          ? <String>{}
          : (selectedTaskIds ?? this.selectedTaskIds),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  TasksViewModelState clearError() {
    // ignore: avoid_redundant_argument_values
    return copyWith(error: null, updateError: true);
  }

  @override
  TasksViewModelState withError(String? error) {
    // ignore: avoid_redundant_argument_values
    return copyWith(error: error, updateError: true);
  }

  @override
  TasksViewModelState withLoading(bool isLoading) {
    // ignore: avoid_redundant_argument_values
    return copyWith(isLoading: isLoading);
  }
}

class TasksViewModel extends BaseViewModel<TasksViewModelState> {
  TasksViewModel() : super();

  TaskPaginationService get _paginationService =>
      ref.read(taskPaginationServiceProvider);
  TaskRepository get _taskRepository => ref.read(taskRepositoryProvider);

  @override
  TasksViewModelState build() {
    return TasksViewModelState.initial();
  }

  @override
  void onInitialize() {
    super.onInitialize();
    loadInitial();
  }

  Future<void> loadInitial() async {
    await _loadPage(
      page: 0,
      replace: true,
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isLoading: isLoading);
      },
    );
  }

  Future<void> refresh() async {
    await _loadPage(
      page: 0,
      replace: true,
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isRefreshing: isLoading);
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasMore) {
      return;
    }
    await _loadPage(
      page: state.pagination.nextPage,
      replace: false,
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isLoadingMore: isLoading);
      },
    );
  }

  Future<void> applySearch(String query) async {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    await loadInitial();
  }

  Future<void> clearSearch() async {
    if (state.searchQuery.isEmpty) return;
    state = state.copyWith(searchQuery: '');
    await loadInitial();
  }

  Future<void> applyStatusFilter(TaskStatus? status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: status);
    await loadInitial();
  }

  void toggleTaskSelection(String taskId) {
    final updated = Set<String>.from(state.selectedTaskIds);
    if (!updated.add(taskId)) {
      updated.remove(taskId);
    }
    state = state.copyWith(selectedTaskIds: updated);
  }

  void clearSelection() {
    if (state.selectedTaskIds.isEmpty) return;
    state = state.copyWith(clearSelection: true);
  }

  Future<void> deleteTask(String taskId) async {
    await runAsyncOperation(
      () async {
        final result = await _taskRepository.deleteTask(taskId);
        if (result.isFailure || result.data != true) {
          throw Exception(result.error ?? 'Failed to delete task');
        }
        _removeTaskFromState(taskId);
      },
      errorMessage: 'Failed to delete task',
      successMessage: 'Task deleted',
    );
  }

  Future<void> deleteSelectedTasks() async {
    if (state.selectedTaskIds.isEmpty) return;
    final taskIds = List<String>.from(state.selectedTaskIds);
    await runAsyncOperation(
      () async {
        for (final taskId in taskIds) {
          final result = await _taskRepository.deleteTask(taskId);
          if (result.isFailure || result.data != true) {
            throw Exception(result.error ?? 'Failed to delete task');
          }
          _removeTaskFromState(taskId, adjustSelection: false);
        }
        state = state.copyWith(clearSelection: true);
      },
      errorMessage: 'Failed to delete tasks',
      successMessage: 'Tasks deleted',
    );
  }

  Future<void> toggleComplete(String taskId) async {
    final task = state.pagination.items.firstWhere(
      (item) => item.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

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
        _updateTaskInState(result.data!);
      },
      errorMessage: 'Failed to update task',
      successMessage: updatedStatus == TaskStatus.completed
          ? 'Task marked as completed'
          : 'Task marked as active',
    );
  }

  Future<void> upsertTask(Task task) async {
    await runAsyncOperation(
      () async {
        final exists =
            state.pagination.items.any((existing) => existing.id == task.id);
        final result = exists
            ? await _taskRepository.updateTask(task)
            : await _taskRepository.createTask(task);
        if (result.isFailure || result.data == null) {
          throw Exception(result.error ?? 'Failed to save task');
        }
        final saved = result.data!;
        if (exists) {
          _updateTaskInState(saved);
        } else {
          _insertTaskIntoState(saved);
        }
      },
      errorMessage: 'Failed to save task',
      successMessage: 'Task saved',
    );
  }

  void insertTaskIntoCache(Task task) {
    _insertTaskIntoState(task);
  }

  void replaceTaskInCache(Task task) {
    _updateTaskInState(task);
  }

  void removeTaskFromCache(String taskId) {
    _removeTaskFromState(taskId);
  }

  Future<void> _loadPage({
    required int page,
    required bool replace,
    required void Function({required bool isLoading}) loadingHandler,
  }) async {
    await runAsyncOperation(
      () async {
        final result = await _paginationService.getPaginated(
          page: page,
          pageSize: _defaultPageSize,
          searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
          statusFilter: state.statusFilter,
        );
        if (result.isFailure || result.data == null) {
          throw Exception(result.error ?? 'Failed to load tasks');
        }
        final pageData = result.data!;

        if (replace || state.pagination.items.isEmpty || page == 0) {
          state = state.copyWith(
            pagination: pageData,
            isLoadingMore: false,
            isRefreshing: false,
            clearSelection: true,
          );
        } else {
          final mergedItems = <Task>{...state.pagination.items};
          mergedItems.addAll(pageData.items);
          final mergedList = mergedItems.toList();
          state = state.copyWith(
            pagination: state.pagination.copyWith(
              items: mergedList,
              total: pageData.total,
              page: pageData.page,
              pageSize: pageData.pageSize,
              hasMore: pageData.hasMore,
            ),
            isLoadingMore: false,
            isRefreshing: false,
          );
        }
      },
      loadingHandler: loadingHandler,
      errorMessage: 'Failed to load tasks',
    );
  }

  void _removeTaskFromState(String taskId, {bool adjustSelection = true}) {
    final updatedTasks =
        state.pagination.items.where((task) => task.id != taskId).toList();
    final updatedPagination = state.pagination.copyWith(
      items: updatedTasks,
      total: state.pagination.total > 0 ? state.pagination.total - 1 : 0,
      hasMore: state.pagination.hasMore,
    );
    final updatedSelection = Set<String>.from(state.selectedTaskIds)
      ..remove(taskId);
    state = state.copyWith(
      pagination: updatedPagination,
      selectedTaskIds:
          adjustSelection ? updatedSelection : state.selectedTaskIds,
    );
  }

  void _updateTaskInState(Task updatedTask) {
    final updatedTasks = state.pagination.items
        .map((task) => task.id == updatedTask.id ? updatedTask : task)
        .toList();
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: updatedTasks),
    );
  }

  void _insertTaskIntoState(Task newTask) {
    final updatedTasks = <Task>[newTask, ...state.pagination.items];
    state = state.copyWith(
      pagination: state.pagination.copyWith(
        items: updatedTasks,
        total: state.pagination.total + 1,
      ),
    );
  }
}

final tasksViewModelProvider =
    NotifierProvider<TasksViewModel, TasksViewModelState>(
  TasksViewModel.new,
);
