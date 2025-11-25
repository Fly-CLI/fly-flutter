import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/domain/categories.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/features/diagnostics/application/doctor_command.dart';

/// Strategy for doctor command
class DoctorCommandDescriptor extends FlyCommandDescriptor {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check Flutter environment and diagnose issues';

  @override
  List<String> get aliases => ['check', 'diagnose', 'health'];

  @override
  CommandGroup? get group => null;

  @override
  CommandCategory get category => CommandCategory.diagnostics;

  @override
  Command<int> createInstance(CommandContext context) {
    return DoctorCommand.create(context);
  }
}
