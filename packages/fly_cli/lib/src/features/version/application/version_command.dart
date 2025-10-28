import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';

/// VersionCommand using new architecture
class VersionCommand extends FlyCommand {
  VersionCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory VersionCommand.create(CommandContext context) => VersionCommand(context);

  @override
  String get name => 'version';

  @override
  String get description => 'Show version information';

  @override
  ArgParser get argParser {
    final parser = super.argParser
    ..addFlag(
      'check-updates',
      help: 'Check for available updates',
      negatable: false,
    );
    return parser;
  }

  @override
  List<CommandMiddleware> get middleware => [
    LoggingMiddleware(),
  ];

  @override
  Future<CommandResult> execute() async {
    final versionInfo = {
      'version': '0.1.0',
      'build_number': null,
      'git_commit': '3eaaea7',
      'build_date': DateTime.now().toIso8601String(),
    };

    return CommandResult.success(
      command: 'version',
      message: 'Version information retrieved',
      data: versionInfo,
    );
  }
}
