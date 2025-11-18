import '../foundation_model.dart';
import '../naming_utils.dart';
import '../variables/shared_derived_variables.dart';
import '../logger.dart';
import 'cross_cutting_planner.dart';

/// Planner that derives naming variables based on generation mode.
///
/// This handles mode-specific naming logic:
/// - Project mode: derives project name variants and sets default feature/component names
/// - Feature mode: derives feature/component names from input name
/// - Service mode: derives service/component names from input name
class NamingPlanner implements CrossCuttingPlanner {
  @override
  bool canHandle(BaseTemplateVariables base) {
    // Naming is global, so this planner always handles
    return true;
  }

  @override
  SharedDerivedVariables derive(
    BaseTemplateVariables base,
    SharedDerivedVariables acc,
    PlanningLogger logger,
  ) {
    final snakeName = NamingUtils.toSnakeCase(base.name);

    // Derive naming variables based on generation mode
    switch (base.generationMode) {
      case GenerationMode.project:
        return acc.copyWith(
          projectName: base.name,
          projectNameSnake: NamingUtils.toSnakeCase(base.name),
          projectNameCamel: NamingUtils.toCamelCase(base.name),
          projectNamePascal: NamingUtils.toPascalCase(base.name),
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
        );

      case GenerationMode.feature:
        return acc.copyWith(
          projectName: 'acme_app', // Default for tests/context
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
        );

      case GenerationMode.service:
        return acc.copyWith(
          projectName: 'acme_app', // Default for tests/context
          templateVariant: base.templateVariant,
          minFlutterSdk: base.minFlutterSdk,
          minDartSdk: base.minDartSdk,
        );
    }
  }
}

