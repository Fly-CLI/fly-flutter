import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
{{#use_riverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/use_riverpod}}

{{#with_viewmodel}}
{{#use_riverpod}}
import '../../../../../core/foundation/screen/base_screen.dart';
import '{{name}}_view_model.dart';
{{/use_riverpod}}
{{/with_viewmodel}}

{{#with_viewmodel}}
{{#use_riverpod}}
class {{name.pascalCase()}}Screen extends BaseScreen<{{name.pascalCase()}}ViewModel, {{name.pascalCase()}}ViewModelState> {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  NotifierProvider<{{name.pascalCase()}}ViewModel, {{name.pascalCase()}}ViewModelState> getViewModelProvider() {
    return {{name}}ViewModelProvider;
  }

  @override
  Future<void> onRefresh({{name.pascalCase()}}ViewModel viewModel) => viewModel.refresh();

  @override
  Widget buildAccessibleContent(
    BuildContext context,
    {{name.pascalCase()}}ViewModel viewModel,
    {{name.pascalCase()}}ViewModelState viewModelState,
    WidgetRef ref,
  ) {
    final resolvedTitle =
        AppLocalizations.of(context)?.appTitle ?? '{{name.pascalCase()}}';
    return _{{name.pascalCase()}}Body(
      title: resolvedTitle,
      message: viewModelState.message,
      onRefresh: viewModel.refresh,
    );
  }
}
{{/use_riverpod}}
{{/with_viewmodel}}

{{^with_viewmodel}}
class {{name.pascalCase()}}Screen extends StatelessWidget {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final resolvedTitle =
        AppLocalizations.of(context)?.appTitle ?? '{{name.pascalCase()}}';
    return _{{name.pascalCase()}}Body(
      title: resolvedTitle,
      message: '{{name.pascalCase()}} screen is ready.',
      onRefresh: () async {},
    );
  }
}
{{/with_viewmodel}}

class _{{name.pascalCase()}}Body extends StatelessWidget {
  const _{{name.pascalCase()}}Body({
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title screen',
      child: RefreshIndicator.adaptive(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh state'),
                  ),
                  {{#is_form_screen}}
                  const SizedBox(height: 24),
                  Text(
                    'Form ready state',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  {{#requires_validation}}
                  const SizedBox(height: 12),
                  Text(
                    'Validation enabled',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  {{/requires_validation}}
                  {{/is_form_screen}}
                  {{#is_list_screen}}
                  const SizedBox(height: 24),
                  Text(
                    'List view ready',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  {{/is_list_screen}}
                  {{#is_detail_screen}}
                  const SizedBox(height: 24),
                  Text(
                    'Detail view ready',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  {{/is_detail_screen}}
                  {{#with_navigation}}
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Close'),
                  ),
                  {{/with_navigation}}
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

