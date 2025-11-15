{{#is_project}}
{{#features}}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/foundation/screen/base_screen.dart';
import '../view_models/{{feature}}_view_model.dart';

class {{feature.pascalCase()}}Screen extends BaseScreen<{{feature.pascalCase()}}ViewModel, {{feature.pascalCase()}}ViewModelState> {
  const {{feature.pascalCase()}}Screen({super.key});

  @override
  NotifierProvider<{{feature.pascalCase()}}ViewModel, {{feature.pascalCase()}}ViewModelState> getViewModelProvider() {
    return {{feature}}ViewModelProvider;
  }

  @override
  Future<void> onRefresh({{feature.pascalCase()}}ViewModel viewModel) => viewModel.refresh();

  @override
  Widget buildAccessibleContent(
    BuildContext context,
    {{feature.pascalCase()}}ViewModel viewModel,
    {{feature.pascalCase()}}ViewModelState viewModelState,
    WidgetRef ref,
  ) {
    return Semantics(
      label: '{{feature.pascalCase()}} screen',
      child: RefreshIndicator.adaptive(
        onRefresh: () => viewModel.refresh(),
        child: ListView(
          children: [
            Semantics(
              label: 'Hero section',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '{{feature.pascalCase()}}',
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
      ),
    );
  }
}
{{/features}}
{{/is_project}}

