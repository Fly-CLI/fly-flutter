import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';

/// Base screen that wraps [FlyScreen] with accessibility defaults.
abstract class BaseScreen<V extends FlyViewModel<S>, S extends FlyViewModelState<S>>
    extends FlyScreen<V, S> {
  const BaseScreen({super.key});

  @override
  Widget buildContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
    WidgetRef ref,
  ) {
    return Semantics(
      label: runtimeType.toString(),
      explicitChildNodes: true,
      child: SafeArea(
        child: Scaffold(
          body: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: buildAccessibleContent(
                context,
                viewModel,
                viewModelState,
                ref,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Child classes implement their UI inside this method.
  Widget buildAccessibleContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
    WidgetRef ref,
  );
}

