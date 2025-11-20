import 'package:fly_foundation_planning/fly_foundation_planning.dart';
import 'package:fly_cli/src/core/templates/mason_variable_keys.dart';

/// Deriver that sets naming-related variables (snake_case, camelCase, PascalCase).
class NamingDeriver implements VariableDeriver {
  const NamingDeriver();

  @override
  String get id => 'naming';

  @override
  bool supports(GenerationContext ctx) => true; // Always run

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    PlanningLogger logger,
  ) {
    // Extract basic fields from raw vars
    final name = ctx.rawVars[MasonVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';
    final organization = ctx.rawVars[MasonVarKey.organization.key] as String? ??
        ctx.rawVars['organization'] as String? ??
        'com.example';
    final description = ctx.rawVars[MasonVarKey.description.key] as String? ??
        ctx.rawVars['description'] as String? ??
        '';

    var bag = current;
    
    // Set basic fields
    bag = bag.set(MasonVarKey.name.key, name);
    bag = bag.set(MasonVarKey.organization.key, organization);
    bag = bag.set('generation_mode', ctx.mode.key);
    if (description.isNotEmpty) {
      bag = bag.set(MasonVarKey.description.key, description);
    }

    switch (ctx.mode) {
      case GenerationMode.project:
        bag = bag
            .set(MasonVarKey.projectName.key, name)
            .set(MasonVarKey.projectNameSnake.key, NamingUtils.toSnakeCase(name))
            .set(
              MasonVarKey.projectNameCamel.key,
              NamingUtils.toCamelCase(name),
            )
            .set(
              MasonVarKey.projectNamePascal.key,
              NamingUtils.toPascalCase(name),
            );
        break;

      case GenerationMode.feature:
      case GenerationMode.service:
        // For feature/service mode, use default project name
        bag = bag
            .set(MasonVarKey.projectName.key, 'acme_app')
            .set(MasonVarKey.projectNameSnake.key, 'acme_app')
            .set(MasonVarKey.projectNameCamel.key, 'acmeApp')
            .set(MasonVarKey.projectNamePascal.key, 'AcmeApp');
        break;
    }

    // Set template variant and SDK versions if present
    final templateVariant =
        ctx.rawVars[MasonVarKey.templateVariant.key] as String? ??
            ctx.rawVars['template_variant'] as String? ??
            'foundation';
    bag = bag.set(MasonVarKey.templateVariant.key, templateVariant);

    final minFlutterSdk = ctx.rawVars[MasonVarKey.minFlutterSdk.key] as String? ??
        ctx.rawVars['min_flutter_sdk'] as String? ??
        '3.10.0';
    bag = bag.set(MasonVarKey.minFlutterSdk.key, minFlutterSdk);

    final minDartSdk = ctx.rawVars[MasonVarKey.minDartSdk.key] as String? ??
        ctx.rawVars['min_dart_sdk'] as String? ??
        '3.0.0';
    bag = bag.set(MasonVarKey.minDartSdk.key, minDartSdk);

    return bag;
  }
}

