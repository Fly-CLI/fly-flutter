import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';
import 'presets.dart';

/// Planner that bridges the new public schema to legacy internal names.
/// Derives project_name, feature, component_name, and other mode-specific vars.
class CoreVarsPlanner implements PlannerPlugin {
  @override
  bool canHandle(BaseTemplateVariables base) {
    // Core vars are global, so this planner always handles
    return true;
  }

  @override
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  ) {
    final snakeName = _toSnakeCase(base.name);
    final defaultFlyPackages = [
      'fly_core',
      'fly_mvvm',
      'fly_state',
      'fly_navigation',
      'fly_flow_guard',
      'fly_logger',
      'fly_events',
      'fly_networking',
    ];

    // Set mode flags and naming based on generation mode
    switch (base.generationMode) {
      case GenerationMode.project:
        return acc.copyWith(
          isProject: true,
          isFeature: false,
          isService: false,
          activeMode: GenerationMode.project,
          projectName: base.name,
          feature: 'home',
          componentName: 'home',
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
          flyPackages: defaultFlyPackages,
          projectNameSnake: _toSnakeCase(base.name),
          projectNameCamel: _toCamelCase(base.name),
          projectNamePascal: _toPascalCase(base.name),
        );

      case GenerationMode.feature:
        final screenType = base.screenType ?? ScreenType.list;
        return acc.copyWith(
          isProject: false,
          isFeature: true,
          isService: false,
          activeMode: GenerationMode.feature,
          projectName: 'acme_app', // Default for tests/context
          feature: snakeName,
          componentName: snakeName,
          screenType: screenType,
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
          flyPackages: defaultFlyPackages,
        );

      case GenerationMode.service:
        final serviceType = base.serviceType ?? ServiceType.api;
        return acc.copyWith(
          isProject: false,
          isFeature: false,
          isService: true,
          activeMode: GenerationMode.service,
          projectName: 'acme_app', // Default for tests/context
          feature: snakeName,
          componentName: snakeName,
          serviceType: serviceType,
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
          flyPackages: defaultFlyPackages,
        );
    }
  }

  /// Simple snake_case conversion helper.
  String _toSnakeCase(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == char.toUpperCase() && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  /// Converts to camelCase.
  String _toCamelCase(String input) {
    final words =
        input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input.toLowerCase();

    final firstWord = words.first.toLowerCase();
    final otherWords = words.skip(1).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return '$firstWord${otherWords.join()}';
  }

  /// Converts to PascalCase.
  String _toPascalCase(String input) {
    final words =
        input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input;

    return words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
  }
}
