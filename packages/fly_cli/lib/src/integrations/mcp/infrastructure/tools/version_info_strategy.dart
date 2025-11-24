import 'dart:convert';
import 'dart:io';

import 'package:fly_cli/src/generation/cache/infrastructure/sdk_version_cache.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/version_params.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/version_result.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:pub_semver/pub_semver.dart';

/// Strategy for fly.version tool
class VersionInfoStrategy
    extends McpToolStrategy<VersionParams, VersionResult> {
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
  VersionParams paramsFromJson(Map<String, Object?> json) {
    return VersionParams.fromJson(json);
  }

  @override
  TypedToolHandler<VersionParams, VersionResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final checkUpdates = params.checkUpdates ?? false;

      // Get version info
      final versionInfo = VersionUtils.getVersionInfo();

      // Get actual SDK version
      String sdkVersion = 'Unknown';
      try {
        final sdkCache = SdkVersionCache(logger: context.logger);
        final dartVersion = await sdkCache.getDartVersion();
        sdkVersion = dartVersion.toString();
      } catch (e) {
        context.logger.warn('Failed to get Dart SDK version: $e');
        // Try fallback method
        try {
          final result = await Process.run('dart', ['--version'], runInShell: true);
          if (result.exitCode == 0) {
            final output = result.stdout as String;
            final match = RegExp(r'Dart SDK version: (\d+\.\d+\.\d+)').firstMatch(output);
            if (match != null) {
              sdkVersion = match.group(1)!;
            }
          }
        } catch (_) {
          // Keep 'Unknown' if all methods fail
        }
      }

      String? latestVersion;
      bool? updateAvailable;

      if (checkUpdates) {
        await progressNotifier?.notify(
            message: 'Checking for updates...', percent: 50);
        try {
          latestVersion = await _checkLatestVersion();
          if (latestVersion != null) {
            final current = Version.parse(versionInfo.version);
            final latest = Version.parse(latestVersion);
            updateAvailable = latest > current;
          } else {
            updateAvailable = false;
          }
        } catch (e) {
          context.logger.warn('Failed to check for updates: $e');
          updateAvailable = false;
        }
      }

      cancelToken?.throwIfCancelled();

      return VersionResult(
        success: true,
        message: 'Version information retrieved',
        version: versionInfo.version,
        sdkVersion: sdkVersion,
        latestVersion: latestVersion,
        updateAvailable: updateAvailable,
      );
    };
  }

  /// Check for latest version on pub.dev
  Future<String?> _checkLatestVersion() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      try {
        final request = await client.getUrl(
          Uri.parse('https://pub.dev/api/packages/fly_cli'),
        );
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = json.decode(responseBody) as Map<String, dynamic>;
          
          // Get latest version from pub.dev API
          final latest = data['latest'] as Map<String, dynamic>?;
          if (latest != null) {
            final version = latest['version'] as String?;
            return version;
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // Network error or parsing error - return null to indicate failure
      return null;
    }
    
    return null;
  }
}

