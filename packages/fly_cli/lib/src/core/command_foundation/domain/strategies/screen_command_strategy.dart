import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/features/screen/application/add_screen_command.dart';

/// Strategy for screen command
class ScreenCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'screen';

  @override
  String get description => 'Add a new screen component to the current project';

  @override
  List<String> get aliases => [
        'add-screen',
        'generate-screen',
        'new-screen',
        'make-screen',
        'addScreen',
      ];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => const CommandGroup(
        name: 'add',
        description: 'Add new components to the current project',
      );

  @override
  CommandCategory get category => CommandCategory.codeGeneration;

  @override
  Command<int> createInstance(CommandContext context) {
    return AddScreenCommand.create(context);
  }
}

