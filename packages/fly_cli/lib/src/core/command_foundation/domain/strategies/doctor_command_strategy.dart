import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_strategy.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/features/doctor/application/doctor_command.dart';

/// Strategy for doctor command
class DoctorCommandStrategy extends FlyCommandStrategy {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Check Flutter environment and diagnose issues';

  @override
  List<String> get aliases => ['check', 'diagnose', 'health'];

  @override
  FlyCommandType? get parentCommand => null;

  @override
  CommandGroup? get group => null;

  @override
  CommandCategory get category => CommandCategory.diagnostics;

  @override
  Command<int> createInstance(CommandContext context) {
    return DoctorCommand.create(context);
  }
}

