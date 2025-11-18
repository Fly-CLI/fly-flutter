import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';







class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resolvedTitle =
        AppLocalizations.of(context)?.appTitle ?? 'Signin';
    return _SigninBody(
      title: resolvedTitle,
      message: 'Signin screen is ready.',
      onRefresh: () async {},
    );
  }
}


class _SigninBody extends StatelessWidget {
  const _SigninBody({
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
                  
                  
                  
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

