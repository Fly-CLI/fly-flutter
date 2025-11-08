import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/shared/navigation/app_navigation.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
import 'package:foundation_project/features/home/presentation/view_models/home_view_model.dart';
import 'package:foundation_project/features/home/presentation/widgets/quick_action_button.dart';
import 'package:foundation_project/features/home/presentation/widgets/statistics_card.dart';
import 'package:foundation_project/features/home/presentation/widgets/sync_status_widget.dart';
import 'package:foundation_project/l10n/app_localizations.dart';

/// Home screen
class HomeScreen extends FlyScreen<HomeViewModel, HomeViewModelState> {
  const HomeScreen({super.key});

  @override
  NotifierProvider<HomeViewModel, HomeViewModelState> getViewModelProvider() {
    return homeViewModelProvider;
  }

  @override
  Future<void> onRefresh(HomeViewModel viewModel) async {
    await viewModel.refresh();
  }

  @override
  Widget buildContent(
    BuildContext context,
    HomeViewModel viewModel,
    HomeViewModelState viewModelState,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (viewModelState.isLoading && viewModelState.statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => onRefresh(viewModel),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Text(
              l10n.home,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (viewModelState.statistics != null)
              _buildStatisticsCards(context, viewModelState.statistics!),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              l10n.quickActions,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context, viewModel),
            const SizedBox(height: 24),

            // Sync Status
            _buildSyncStatus(context, viewModelState, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, statistics) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StatisticsCard(
          title: l10n.totalTasks,
          count: statistics.totalTasks,
          icon: Icons.task,
          color: theme.colorScheme.primary,
        ),
        StatisticsCard(
          title: l10n.completedTasks,
          count: statistics.completedTasks,
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        StatisticsCard(
          title: l10n.overdueTasks,
          count: statistics.overdueTasks,
          icon: Icons.warning,
          color: Colors.orange,
        ),
        StatisticsCard(
          title: l10n.todayTasks,
          count: statistics.todayTasks,
          icon: Icons.today,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, HomeViewModel viewModel) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        QuickActionButton(
          label: l10n.addTask,
          icon: Icons.add_task,
          onPressed: () {
            AppNavigation.instance.navigateTo(FeatureScreenType.taskForm);
          },
        ),
        QuickActionButton(
          label: l10n.addNote,
          icon: Icons.note_add,
          onPressed: () {
            AppNavigation.instance.navigateTo(FeatureScreenType.noteForm);
          },
        ),
        QuickActionButton(
          label: l10n.syncNow,
          icon: Icons.sync,
          onPressed: () => viewModel.syncNow(),
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSyncStatus(
    BuildContext context,
    HomeViewModelState viewModelState,
    WidgetRef ref,
  ) {
    if (viewModelState.syncStatus == null) {
      return const SizedBox.shrink();
    }

    return SyncStatusWidget(
      syncStatus: viewModelState.syncStatus!,
      onSyncPressed: () {
        final viewModel = ref.read(getViewModelProvider().notifier);
        viewModel.syncNow();
      },
    );
  }

  @override
  bool get showRefreshIndicator => true;
}

