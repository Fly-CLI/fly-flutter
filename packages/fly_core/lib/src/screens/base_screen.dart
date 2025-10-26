import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_core/src/models/view_state.dart';
import 'package:fly_core/src/viewmodels/base_viewmodel.dart';
import 'package:fly_core/src/widgets/error_widget.dart' as core;
import 'package:fly_core/src/widgets/loading_widget.dart';

/// Base class for all screens in Fly CLI applications
/// 
/// Provides common functionality for screen lifecycle management,
/// state handling, and error display using BaseViewModel.
abstract class BaseScreen<T, VM extends BaseViewModel<T>>
    extends ConsumerStatefulWidget {
  /// Creates a BaseScreen
  const BaseScreen({super.key});

  /// Create the ViewModel provider for this screen
  Provider<VM> createViewModelProvider();

  /// Build the content of the screen
  /// 
  /// This method is called when the ViewModel state is success.
  /// Override this method to define the screen's content.
  Widget buildContent(BuildContext context, VM viewModel);
  
  /// Build the loading widget
  /// 
  /// Override this method to customize the loading display.
  Widget buildLoading(BuildContext context) => const LoadingWidget();
  
  /// Build the error widget
  /// 
  /// Override this method to customize the error display.
  Widget buildError(BuildContext context, Object error) => 
      core.ErrorWidget(error: error);
  
  /// Build the idle widget
  /// 
  /// Override this method to customize the idle state display.
  Widget buildIdle(BuildContext context) => const SizedBox.shrink();
  
  /// Called when the screen is initialized
  /// 
  /// Override this method to perform initialization logic.
  void onInitialize(VM viewModel) {
    // Default implementation does nothing
  }
  
  /// Called when the ViewModel state changes
  /// 
  /// Override this method to react to state changes.
  void onStateChanged(VM viewModel, ViewState<T> state) {
    // Default implementation does nothing
  }
  
  /// Called when the screen is disposed
  /// 
  /// Override this method to perform cleanup logic.
  void onDispose(VM viewModel) {
    // Default implementation does nothing
  }
  
  @override
  ConsumerState<BaseScreen<T, VM>> createState() => _BaseScreenState<T, VM>();
}

class _BaseScreenState<T, VM extends BaseViewModel<T>>
    extends ConsumerState<BaseScreen<T, VM>> {
  ViewState<T>? _previousState;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read<VM>(widget.createViewModelProvider());
      widget.onInitialize(viewModel);
      viewModel.initialize();
    });
  }

  void _handleStateChange(VM viewModel, ViewState<T> currentState) {
    if (_previousState != currentState) {
      _previousState = currentState;
      if (mounted) {
        widget.onStateChanged(viewModel, currentState);
      }
    }
  }
  
  @override
  void dispose() {
    final viewModel = ref.read<VM>(widget.createViewModelProvider());
    widget.onDispose(viewModel);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final viewModelProvider = widget.createViewModelProvider();
    final viewModel = ref.watch<VM>(viewModelProvider);

    return Scaffold(body: _buildBody(viewModel));
  }

  Widget _buildBody(VM viewModel) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch<ViewState<T>>(
          widget.createViewModelProvider().select((vm) => vm.currentState),
        );

        _handleStateChange(viewModel, state);

        return state.when(
          idle: () => widget.buildIdle(context),
          loading: () => widget.buildLoading(context),
          error: (error, stackTrace) => widget.buildError(context, error),
          success: (data) => widget.buildContent(context, viewModel),
        );
      },
    );
  }
}

/// Mixin for screens that need to handle refresh operations
mixin RefreshableScreenMixin<T, VM extends BaseViewModel<T>> 
    on BaseScreen<T, VM> {
  /// Build a refreshable widget
  /// 
  /// This method wraps the content in a RefreshIndicator.
  Widget buildRefreshableContent(BuildContext context, VM viewModel) =>
      RefreshIndicator(
        onRefresh: () async {
          if (viewModel is RefreshableMixin<T>) {
            await viewModel.refresh();
          }
        },
        child: buildContent(context, viewModel),
      );
  
  @override
  Widget buildContent(BuildContext context, VM viewModel) =>
      buildRefreshableContent(context, viewModel);
}

/// Mixin for screens that need to handle search
mixin SearchableScreenMixin<T, VM extends BaseViewModel<T>> 
    on BaseScreen<T, VM> {
  /// Build a searchable widget
  /// 
  /// This method adds a search bar to the screen.
  Widget buildSearchableContent(BuildContext context, VM viewModel) =>
      Column(
        children: [
          _buildSearchBar(context, viewModel),
          Expanded(child: buildContent(context, viewModel)),
        ],
      );
  
  Widget _buildSearchBar(BuildContext context, VM viewModel) {
    if (viewModel is! SearchMixin<T>) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (query) {
          if (query.isEmpty) {
            viewModel.clearSearch();
          } else {
            viewModel.search(query);
          }
        },
      ),
    );
  }
  
  @override
  Widget buildContent(BuildContext context, VM viewModel) =>
      buildSearchableContent(context, viewModel);
}

/// Mixin for screens that need to handle pagination
mixin PaginatedScreenMixin<T, VM extends BaseViewModel<T>> 
    on BaseScreen<T, VM> {
  /// Build a paginated widget
  /// 
  /// This method adds pagination support to the screen.
  Widget buildPaginatedContent(BuildContext context, VM viewModel) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >= 
                  notification.metrics.maxScrollExtent) {
            if (viewModel is PaginationMixin<T> && viewModel.hasMoreData) {
              viewModel.loadMore();
            }
          }
          return false;
        },
        child: buildContent(context, viewModel),
      );
  
  @override
  Widget buildContent(BuildContext context, VM viewModel) =>
      buildPaginatedContent(context, viewModel);
}
