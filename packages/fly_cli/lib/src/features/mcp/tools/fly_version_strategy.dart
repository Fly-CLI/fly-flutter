import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/utils/version_utils.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_version_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_version_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.version tool
class FlyVersionStrategy
    extends McpToolStrategy<FlyVersionParams, FlyVersionResult> {
  @override
  String get name => 'fly.version';

  @override
  String get description => 'Show version information';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'checkUpdates': Schema.bool(),
        },
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'message': Schema.string(),
          'version': Schema.string(),
          'sdkVersion': Schema.string(),
          'latestVersion': Schema.string(),
          'updateAvailable': Schema.bool(),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => true;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  Duration? get timeout => const Duration(seconds: 30);

  @override
  FlyVersionParams paramsFromJson(Map<String, Object?> json) {
    return FlyVersionParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyVersionParams, FlyVersionResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final checkUpdates = params.checkUpdates ?? false;

      // Get version info
      final versionInfo = VersionUtils.getVersionInfo();

      String? latestVersion;
      bool? updateAvailable;

      if (checkUpdates) {
        await progressNotifier?.notify(
            message: 'Checking for updates...', percent: 50);
        // TODO: Implement actual update check logic
        latestVersion = null;
        updateAvailable = false;
      }

      cancelToken?.throwIfCancelled();

      return FlyVersionResult(
        success: true,
        message: 'Version information retrieved',
        version: versionInfo.version,
        sdkVersion: 'dart', // TODO: Get actual SDK version
        latestVersion: latestVersion,
        updateAvailable: updateAvailable,
      );
    };
  }
}
