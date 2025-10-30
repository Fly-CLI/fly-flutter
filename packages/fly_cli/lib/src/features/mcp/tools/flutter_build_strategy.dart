import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_build_params.dart';
import 'package:fly_cli/src/features/mcp/tools/flutter_build_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.build tool
class FlutterBuildStrategy
    extends McpToolStrategy<FlutterBuildParams, FlutterBuildResult> {
  @override
  String get name => 'flutter.build';

  @override
  String get description => 'Build the current Flutter app';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'platform': Schema.string(enumValues: ['android', 'ios', 'web', 'macos', 'windows', 'linux']),
          'release': Schema.bool(),
          'debug': Schema.bool(),
          'profile': Schema.bool(),
          'target': Schema.string(),
          'dartDefine': ObjectSchema(
            additionalProperties: Schema.string(),
          ),
        },
        required: ['platform'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'exitCode': Schema.int(),
          'buildPath': Schema.string(),
          'logResourceUri': Schema.string(),
          'message': Schema.string(),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => true;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => false;

  @override
  Duration? get timeout => const Duration(minutes: 30);

  @override
  int? get maxConcurrency => 3;

  @override
  FlutterBuildParams paramsFromJson(Map<String, Object?> json) {
    return FlutterBuildParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlutterBuildParams, FlutterBuildResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      if (params.platform.isEmpty) {
        return FlutterBuildResult(
          success: false,
          message: 'Missing required parameter: platform',
        );
      }

      final release = params.release ?? true;
      final profile = params.profile ?? false;
      final target = params.target;
      final dartDefine = params.dartDefine ?? <String, String>{};

      await progressNotifier?.notify(
          message: 'Preparing build for ${params.platform}...', percent: 10);

      final args = <String>['build', params.platform];

      if (release) {
        args.add('--release');
      } else if (profile) {
        args.add('--profile');
      } else {
        args.add('--debug');
      }

      if (target != null && target.isNotEmpty) {
        args.addAll(['--target', target]);
      }

      // Add dart-define arguments
      for (final entry in dartDefine.entries) {
        args.addAll(['--dart-define', '${entry.key}=${entry.value}']);
      }

      await progressNotifier?.notify(message: 'Building Flutter app...', percent: 30);

      final proc = await Process.start('flutter', args);

      final buildId = 'flutter_build_${DateTime.now().microsecondsSinceEpoch}';

      // Monitor cancellation
      cancelToken?.onCancel.then((_) {
        try {
          proc.kill();
        } catch (_) {
          // Ignore errors
        }
      });

      final outputBuffer = StringBuffer();
      final errorBuffer = StringBuffer();

      // Get log provider from resource registry (capture in closure)
      final logProvider = resourceRegistry.logProvider;
      if (logProvider == null) {
        throw StateError('LogResourceProvider not found in ResourceRegistry');
      }

      proc.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
        outputBuffer.write(chunk);
        logProvider.storeBuildLog(buildId, chunk);
      });

      proc.stderr.transform(const SystemEncoding().decoder).listen((chunk) {
        errorBuffer.write(chunk);
        logProvider.storeBuildLog(buildId, chunk);
      });

      await progressNotifier?.notify(message: 'Compiling...', percent: 50);

      // Wait for build to complete
      final exitCode = await proc.exitCode;

      cancelToken?.throwIfCancelled();

      // Try to extract build path from output
      String? buildPath;
      if (params.platform == 'android') {
        final buildMode =
            release ? 'release' : profile ? 'profile' : 'debug';
        buildPath = 'build/app/outputs/flutter-apk/app-$buildMode.apk';
      } else if (params.platform == 'ios') {
        buildPath = 'build/ios/iphoneos/Runner.app';
      } else if (params.platform == 'web') {
        buildPath = 'build/web';
      } else {
        buildPath = 'build/${params.platform}';
      }

      return FlutterBuildResult(
        success: exitCode == 0,
        exitCode: exitCode,
        buildPath: buildPath,
        logResourceUri: 'logs://build/$buildId',
        message: exitCode == 0
            ? 'Build completed successfully'
            : 'Build failed with exit code $exitCode',
      );
    };
  }
}



