import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/flag_factory.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';

/// VersionCommand using new architecture
class VersionCommand extends FlyCommand {
  VersionCommand(super.context);

  /// Factory constructor for enum-based command creation
  factory VersionCommand.create(CommandContext context) =>
      VersionCommand(context);

  @override
  String get name => 'version';

  @override
  String get description => 'Show version information';

  @override
  List<CliFlag> get flags => [const VersionCheckUpdatesFlag()];

  @override
  List<CommandMiddleware> get middleware => [
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
