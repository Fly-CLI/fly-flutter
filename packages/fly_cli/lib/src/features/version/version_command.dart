import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/command_result.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';

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
    final versionInfo = VersionUtils.getVersionInfo().toJson();

    return CommandResult.success(
      command: 'version',
      message: 'Version information retrieved',
      data: versionInfo,
    );
  }
}
