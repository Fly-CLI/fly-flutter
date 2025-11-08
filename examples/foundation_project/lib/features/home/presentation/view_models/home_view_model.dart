import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/core/foundation/base_view_model.dart';
import 'package:foundation_project/core/providers/service_providers.dart';
import 'package:foundation_project/core/services/statistics_service.dart';
import 'package:foundation_project/core/services/sync_service.dart';
import 'package:foundation_project/features/home/data/models/statistics_entity.dart';
import 'package:foundation_project/features/home/data/models/sync_status_entity.dart';

/// Home ViewModel state
class HomeViewModelState
    implements FlyViewModelState<HomeViewModelState> {
  final StatisticsEntity? statistics;
  final SyncStatusEntity? syncStatus;
  final bool isRefreshing;

  @override
  final bool isLoading;

  @override
  final String? error;

  @override
  bool get hasError => error != null;

  HomeViewModelState({
    required this.isLoading,
    this.error,
    this.statistics,
    this.syncStatus,
    this.isRefreshing = false,
  });

  @override
  HomeViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
    StatisticsEntity? statistics,
    SyncStatusEntity? syncStatus,
    bool? isRefreshing,
    bool clearStatistics = false,
    bool clearSyncStatus = false,
  }) {
    return HomeViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
      statistics: clearStatistics ? null : (statistics ?? this.statistics),
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  HomeViewModelState withLoading(bool isLoading) {
    return copyWith(isLoading: isLoading);
  }

  @override
  HomeViewModelState withError(String? error) {
    return copyWith(error: error, updateError: true);
  }

  @override
  HomeViewModelState clearError() {
    return copyWith(error: null, updateError: true);
  }

  factory HomeViewModelState.initial() {
    return HomeViewModelState(isLoading: false);
  }

  factory HomeViewModelState.loading() {
    return HomeViewModelState(isLoading: true);
  }
}

/// Home ViewModel
/// 
/// Example ViewModel demonstrating proper use of runAsyncOperation for async operations.
/// All async operations use runAsyncOperation to ensure consistent error handling,
/// loading state management, and network awareness.
class HomeViewModel extends BaseViewModel<HomeViewModelState> {

  StatisticsService get _statisticsService => ref.read(statisticsServiceProvider);
  SyncService get _syncService => ref.read(syncServiceProvider);

  @override
  HomeViewModelState build() {
    return HomeViewModelState.initial();
  }

  @override
  void onInitialize() {
    super.onInitialize();
    loadData();
  }

  /// Load all data
  /// 
  /// Loads both statistics and sync status concurrently.
  Future<void> loadData() async {
    await runAsyncOperation(() async {
      await Future.wait([
        loadStatistics(),
        loadSyncStatus(),
      ]);
    });
  }

  /// Load statistics
  /// 
  /// Uses runAsyncOperation to handle loading states and errors automatically.
  /// The service returns AppResult, so we unwrap it in the operation closure.
  Future<void> loadStatistics() async {
    await runAsyncOperation(
      () async {
        final serviceResult = await _statisticsService.getStatistics();
        state = state.copyWith(statistics: serviceResult.data);
      },
      errorMessage: 'Failed to load statistics',
    );
  }

  /// Load sync status
  /// 
  /// Uses runAsyncOperation to handle errors automatically.
  /// This operation doesn't set loading state since it's typically called
  /// alongside other operations that manage the loading state.
  /// The service returns AppResult, so we unwrap it in the operation closure.
  Future<void> loadSyncStatus() async {
    await runAsyncOperation(
      () async {
        final serviceResult = await _syncService.getSyncStatus();
        state = state.copyWith(syncStatus: serviceResult.data);
      },
      errorMessage: 'Failed to load sync status',
      loadingHandler: ({required bool isLoading}) {},
    );
  }

  /// Refresh all data
  /// 
  /// Refreshes all data and shows a refreshing indicator.
  Future<void> refresh() async {
    await runAsyncOperation(
      loadData,
      loadingHandler: ({required bool isLoading}) {
        state = state.copyWith(isRefreshing: isLoading);
      },
    );
  }

  /// Sync now
  /// 
  /// Performs a sync operation and reloads related data on success.
  /// The service returns AppResult, so we unwrap it in the operation closure.
  Future<void> syncNow() async {
    await runAsyncOperation(
      () async {
        await _syncService.sync();
        await loadSyncStatus();
        await loadStatistics();
      },
      errorMessage: 'Failed to sync',
      successMessage: 'Sync completed successfully',
    );
  }
}

/// Home ViewModel provider
final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeViewModelState>(
  () {
    return HomeViewModel();
  },
);

