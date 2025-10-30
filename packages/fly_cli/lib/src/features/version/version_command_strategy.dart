import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_type.dart';
import 'package:fly_cli/src/features/version/version_command.dart';

/// Strategy for version command
class VersionCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'version';

  @override
  String get description => 'Show version information and check for updates';

  @override
  List<String> get aliases => ['--version', '-v', 'info'];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => null;

  @override
  CommandCategory get category => CommandCategory.information;

  @override
  Command<int> createInstance(CommandContext context) {
    return VersionCommand.create(context);
  }
}

