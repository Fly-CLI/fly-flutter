{{#is_project}}
import 'package:flutter/material.dart';
{{#features}}
import '../../features/{{feature}}/presentation/{{feature}}_screen.dart';
{{/features}}
import 'feature_screen_type.dart';

class AppRouteConfig {
  static const String initialRoute = '/{{features.0}}';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
    {{#features}}
      case '/{{feature}}':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const {{feature.pascalCase()}}Screen(),
        );
    {{/features}}
      default:
        return onUnknownRoute(settings);
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const {{features.0.pascalCase()}}Screen(),
    );
  }
}
{{/is_project}}
