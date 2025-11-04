import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/definitions/categories.dart';
import 'package:fly_cli/src/features/generate/screen/generate_screen_command.dart';

/// Strategy for screen command
class ScreenCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'screen';

  @override
  String get description =>
      'Generate a new screen component to the current project';

  @override
  List<String> get aliases => [
        'generate-screen',
        'add-screen',
        'new-screen',
        'make-screen',
        'generateScreen',
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
    return GenerateScreenCommand.create(context);
  }
}
