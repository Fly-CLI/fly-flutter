import 'package:fly_foundation_planning/fly_foundation_planning.dart';

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
    final name = ctx.rawVars[MasonVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';

    var bag = current;

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

