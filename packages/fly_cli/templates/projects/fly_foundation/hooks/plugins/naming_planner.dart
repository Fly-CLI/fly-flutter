import 'package:mason/mason.dart';

import 'foundation_model.dart';
import 'planner.dart';
import 'naming_utils.dart';

/// Planner that derives naming variables based on generation mode.
///
/// This handles mode-specific naming logic:
/// - Project mode: derives project name variants and sets default feature/component names
/// - Feature mode: derives feature/component names from input name
/// - Service mode: derives service/component names from input name
///
/// Note: Mode flags (isProject, isFeature, isService) are handled by CompositionPlanner.
class NamingPlanner implements PlannerPlugin {
  @override
  bool canHandle(BaseTemplateVariables base) {
    // Naming is global, so this planner always handles
    return true;
  }

  @override
  DerivedTemplateVariables derive(
    BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,
  ) {
    final snakeName = NamingUtils.toSnakeCase(base.name);

    // Derive naming variables based on generation mode
    switch (base.generationMode) {
      case GenerationMode.project:
        return acc.copyWith(
          projectName: base.name,
          feature: 'home',
          componentName: 'home',
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
          projectNameVariants: ProjectName(
            snake: NamingUtils.toSnakeCase(base.name),
            camel: NamingUtils.toCamelCase(base.name),
            pascal: NamingUtils.toPascalCase(base.name),
          ),
        );

      case GenerationMode.feature:
        final screenType = base.screenType ?? ScreenType.list;
        return acc.copyWith(
          projectName: 'acme_app', // Default for tests/context
          feature: snakeName,
          componentName: snakeName,
          screenType: screenType,
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
        );

      case GenerationMode.service:
        final serviceType = base.serviceType ?? ServiceType.api;
        return acc.copyWith(
          projectName: 'acme_app', // Default for tests/context
          feature: snakeName,
          componentName: snakeName,
          serviceType: serviceType,
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
        );
    }
  }
}

