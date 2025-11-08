import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_core/fly_core.dart' hide BaseViewModel;
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/core/providers/service_providers.dart';

/// Base view model class for all view models in the foundation project.
///
/// Extends [FlyViewModel] to provide common functionality and setup
/// that can be shared across all view models in the application.
///
/// This base class automatically initializes:
/// - Logger (based on the runtime type name)
/// - Connectivity checker (from GlobalContainer)
///
/// **Usage:**
/// ```dart
/// class MyViewModel extends BaseViewModel<MyViewModelState> {
///   MyViewModel() : super();
///
///   @override
///   MyViewModelState build() {
///     return MyViewModelState.initial();
///   }
///
///   // Access logger via logger field
///   void doSomething() {
///     logger.info('Doing something');
///   }
/// }
/// ```
abstract class BaseViewModel<S extends FlyViewModelState<S>>
    extends FlyViewModel<S> {
  /// Creates a [BaseViewModel].
  ///
  /// Automatically initializes logger and connectivity checker from GlobalContainer.
  /// The logger name is automatically set to the runtime type name of the class.
  ///
  /// [logger] - Optional logger instance. If provided, uses this instead of creating one
  /// [connectivityChecker] - Optional connectivity checker. If not provided, gets from GlobalContainer
  BaseViewModel({
    super.logger,
    ConnectivityChecker? connectivityChecker,
  }) : super(
          connectivityChecker: connectivityChecker ??
              GlobalContainer.instance.read(connectivityCheckerProvider),
        );
}
