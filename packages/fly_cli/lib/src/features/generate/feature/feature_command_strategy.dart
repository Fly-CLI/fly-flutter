import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';
import 'package:fly_cli/src/features/generate/feature/generate_feature_command.dart';

/// Strategy for feature command
class FeatureCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'feature';

  @override
  String get description =>
      'Generate a new feature (screen) component for the current project';

  @override
  List<String> get aliases => [
        'generate-feature',
        'add-feature',
        'new-feature',
        'make-feature',
        'generateFeature',
      ];

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'generate',
        description: 'Generate new components for the current project',
      );

  @override
  CommandCategory get category => CommandCategory.generation;

  @override
  Command<int> createInstance(CommandContext context) {
    return GenerateFeatureCommand.create(context);
  }
}
