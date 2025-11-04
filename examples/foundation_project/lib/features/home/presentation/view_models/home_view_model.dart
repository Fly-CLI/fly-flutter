import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/mvvm/view_model.dart';
import 'package:foundation_project/core/foundation/utils/app_logger.dart';
import 'package:foundation_project/core/providers/service_providers.dart';
import 'package:foundation_project/core/services/statistics_service.dart';
import 'package:foundation_project/core/services/sync_service.dart';
import 'package:foundation_project/features/home/data/models/statistics.dart';
import 'package:foundation_project/features/home/data/models/sync_status.dart';

/// Home ViewModel state
class HomeViewModelState extends ViewModelState {
  final Statistics? statistics;
  final SyncStatus? syncStatus;
  final bool isRefreshing;

  @override
  final bool isLoading;

  @override
  final String? error;

  HomeViewModelState({
    required this.isLoading,
    this.error,
    this.statistics,
    this.syncStatus,
    this.isRefreshing = false,
  });

  HomeViewModelState copyState({bool? isLoading, String? error}) {
    return HomeViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      statistics: statistics,
      syncStatus: syncStatus,
      isRefreshing: isRefreshing,
    );
  }

  HomeViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Statistics? statistics,
    SyncStatus? syncStatus,
    bool? isRefreshing,
    bool clearStatistics = false,
    bool clearSyncStatus = false,
  }) {
    return HomeViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statistics: clearStatistics ? null : (statistics ?? this.statistics),
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
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
/// Example ViewModel demonstrating proper use of performAsync for async operations.
/// All async operations use performAsync to ensure consistent error handling,
/// loading state management, and network awareness.
class HomeViewModel extends ViewModel<HomeViewModelState> {
  final AppLogger _logger = AppLogger('HomeViewModel');

  HomeViewModel();

  StatisticsService get _statisticsService => ref.read(statisticsServiceProvider);
  SyncService get _syncService => ref.read(syncServiceProvider);

  @override
  HomeViewModelState build() {
    return HomeViewModelState.initial();
  }

  @override
  HomeViewModelState copyState({bool? isLoading, String? error}) {
    return state.copyState(isLoading: isLoading, error: error);
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
    await performAsync(() async {
      await Future.wait([
        loadStatistics(),
        loadSyncStatus(),
      ]);
    });
  }

  /// Load statistics
  /// 
  /// Uses performAsync to handle loading states and errors automatically.
  /// The service returns AppResult, so we unwrap it in the operation closure.
  Future<void> loadStatistics() async {
    await performAsync(
      () async {
        final serviceResult = await _statisticsService.getStatistics();
        state = state.copyWith(statistics: serviceResult.data);
      },
      errorMessage: 'Failed to load statistics',
    );
  }

  /// Load sync status
  /// 
  /// Uses performAsync to handle errors automatically.
  /// This operation doesn't set loading state since it's typically called
  /// alongside other operations that manage the loading state.
  /// The service returns AppResult, so we unwrap it in the operation closure.
  Future<void> loadSyncStatus() async {
    await performAsync(
      () async {
        final serviceResult = await _syncService.getSyncStatus();
        state = state.copyWith(syncStatus: serviceResult.data);
      },
      errorMessage: 'Failed to load sync status',
      loadingHandler: (_) {}, // Don't show loading for background sync status checks
    );
  }

  /// Refresh all data
  /// 
  /// Refreshes all data and shows a refreshing indicator.
  Future<void> refresh() async {
    await performAsync(
      loadData,
      loadingHandler: (isLoading) {
        state.copyWith(isRefreshing: isLoading);
      },
    );
  }

  /// Sync now
  /// 
  /// Performs a sync operation and reloads related data on success.
  /// The service returns AppResult, so we unwrap it in the operation closure.
  Future<void> syncNow() async {
    await performAsync(
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
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeViewModelState>(HomeViewModel.new);

