import 'package:fly_mvvm/fly_mvvm.dart';

/// Base screen class for all screens in the foundation project.
///
/// Extends [FlyScreen] to provide common functionality and configuration
/// that can be shared across all screens in the application.
///
/// **Usage:**
/// ```dart
/// class MyScreen extends BaseScreen<MyViewModel, MyViewModelState> {
///   const MyScreen({super.key});
///
///   @override
///   NotifierProvider<MyViewModel, MyViewModelState> getViewModelProvider() {
///     return myViewModelProvider;
///   }
///
///   @override
///   Future<void> onRefresh(MyViewModel viewModel) async {
///     await viewModel.refresh();
///   }
///
///   @override
///   Widget buildContent(
///     BuildContext context,
///     MyViewModel viewModel,
///     MyViewModelState viewModelState,
///     WidgetRef ref,
///   ) {
///     // Build your content here
///   }
/// }
/// ```
abstract class BaseScreen<V extends FlyViewModel<S>,
    S extends FlyViewModelState<S>> extends FlyScreen<V, S> {
  /// Creates a [BaseScreen].
  ///
  /// [key] - Widget key
  /// [shouldRefresh] - Whether the screen should refresh on appear
  /// [screenTitle] - Title of the screen
  /// [showRefreshIndicator] - Whether to show pull-to-refresh indicator
  /// [enableFeedback] - Whether to enable automatic feedback handling
  const BaseScreen({
    super.key,
    super.enableFeedback = true,
  });
}
