import 'package:foundation_project/core/di/global_container.dart';
import 'package:foundation_project/core/providers/logger_provider.dart';
import 'package:foundation_project/core/providers/service_providers.dart';
import 'package:fly_mvvm/fly_mvvm.dart';

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
  BaseViewModel({
    super.asyncCoordinator,
    super.feedbackCoordinator,
  });
}