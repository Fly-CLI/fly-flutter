import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/foundation/screen/base_screen.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends BaseScreen<HomeViewModel, HomeViewModelState> {
  const HomeScreen({super.key});

  @override
  NotifierProvider<HomeViewModel, HomeViewModelState> getViewModelProvider() {
    return homeViewModelProvider;
  }

  @override
  Future<void> onRefresh(HomeViewModel viewModel) => viewModel.refresh();

  @override
  Widget buildAccessibleContent(
    BuildContext context,
    HomeViewModel viewModel,
    HomeViewModelState viewModelState,
    WidgetRef ref,
  ) {
    final localization = AppLocalizations.of(context);
    final greeting = localization?.homeGreeting ?? 'Welcome';

    return RefreshIndicator.adaptive(
      onRefresh: () => viewModel.refresh(),
      child: ListView(
        children: [
          Semantics(
            label: 'Hero section',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  viewModelState.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: viewModel.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh state'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
