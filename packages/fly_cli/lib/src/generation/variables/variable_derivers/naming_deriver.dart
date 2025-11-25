import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/generation/utils/mason_variable_keys.dart';

/// Deriver that sets naming-related variables (snake_case, camelCase, PascalCase).
class NamingDeriver implements VariableDeriver {
  /// Constructor
  const NamingDeriver();

  @override
  String get id => 'naming';

  @override
  bool supports(GenerationContext ctx) => true; // Always run

  @override
  VariableBag derive(
    GenerationContext ctx,
    VariableBag current,
    ComposerLogger logger,
  ) {
    // Extract basic fields from raw vars
    final name =
        ctx.rawVars[BaseVarKey.name.key] as String? ??
        ctx.rawVars['name'] as String? ??
        'unnamed';
    final organization =
        ctx.rawVars[BaseVarKey.organization.key] as String? ??
        ctx.rawVars['organization'] as String? ??
        'com.example';
    final description =
        ctx.rawVars[BaseVarKey.description.key] as String? ??
        ctx.rawVars['description'] as String? ??
        '';

    var bag = current;

    // Set basic fields
    bag = bag.set(BaseVarKey.name.key, name);
    bag = bag.set(BaseVarKey.organization.key, organization);
    bag = bag.set(BaseVarKey.generationMode.key, ctx.mode.key);
    if (description.isNotEmpty) {
      bag = bag.set(BaseVarKey.description.key, description);
    }

    switch (ctx.mode) {
      case GenerationMode.project:
        bag = bag
            .set(BaseVarKey.projectName.key, name)
            .set(
              BaseVarKey.projectNameSnake.key,
              NamingUtils.toSnakeCase(name),
            )
            .set(
              BaseVarKey.projectNameCamel.key,
              NamingUtils.toCamelCase(name),
            )
            .set(
              BaseVarKey.projectNamePascal.key,
              NamingUtils.toPascalCase(name),
            );

      case GenerationMode.feature:
      case GenerationMode.service:
        // For feature/service mode, use default project name
        bag = bag
            .set(BaseVarKey.projectName.key, 'acme_app')
            .set(BaseVarKey.projectNameSnake.key, 'acme_app')
            .set(BaseVarKey.projectNameCamel.key, 'acmeApp')
            .set(BaseVarKey.projectNamePascal.key, 'AcmeApp');
    }

    // Set template variant and SDK versions if present
    final templateVariant =
        ctx.rawVars[BaseVarKey.templateVariant.key] as String? ??
        ctx.rawVars['template_variant'] as String? ??
        'foundation';
    bag = bag.set(BaseVarKey.templateVariant.key, templateVariant);

    final minFlutterSdk =
        ctx.rawVars[BaseVarKey.minFlutterSdk.key] as String? ??
        ctx.rawVars['min_flutter_sdk'] as String? ??
        '3.10.0';
    bag = bag.set(BaseVarKey.minFlutterSdk.key, minFlutterSdk);

    final minDartSdk =
        ctx.rawVars[BaseVarKey.minDartSdk.key] as String? ??
        ctx.rawVars['min_dart_sdk'] as String? ??
        '3.0.0';
    return bag.set(BaseVarKey.minDartSdk.key, minDartSdk);
  }
}
