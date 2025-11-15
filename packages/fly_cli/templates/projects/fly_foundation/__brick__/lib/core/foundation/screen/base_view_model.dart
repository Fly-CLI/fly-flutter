{{#is_project}}
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:fly_logger/fly_logger.dart';

abstract class BaseViewModel<S extends FlyViewModelState<S>> extends FlyViewModel<S> {
  BaseViewModel({super.asyncCoordinator, super.feedbackCoordinator}) {
    logger = FlyLogger(runtimeType.toString());
  }

  late final FlyLogger logger;
}
{{/is_project}}
