import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.build tool
class FlutterBuildStrategy extends McpToolStrategy {
  @override
  String get name => 'flutter.build';

  @override
  String get description => 'Build the current Flutter app';

  @override
  Map<String, Object?> get paramsSchema => {
        'type': 'object',
        'properties': {
          'platform': {
            'type': 'string',
            'enum': ['android', 'ios', 'web', 'macos', 'windows', 'linux'],
          },
          'release': {'type': 'boolean', 'default': true},
          'debug': {'type': 'boolean', 'default': false},
          'profile': {'type': 'boolean', 'default': false},
          'target': {'type': 'string'},
          'dartDefine': {
            'type': 'object',
            'additionalProperties': {'type': 'string'},
          },
        },
        'required': ['platform'],
        'additionalProperties': false,
      };

  @override
  Map<String, Object?> get resultSchema => {
        'type': 'object',
        'properties': {
          'success': {'type': 'boolean'},
          'exitCode': {'type': 'integer'},
          'buildPath': {'type': 'string'},
          'logResourceUri': {'type': 'string'},
          'message': {'type': 'string'},
        },
        'required': ['success', 'message'],
      };

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
  ToolHandler createHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final platform = params['platform'] as String?;
      if (platform == null) {
        return {
          'success': false,
          'message': 'Missing required parameter: platform',
        };
      }

      final release = params['release'] as bool? ?? true;
      final profile = params['profile'] as bool? ?? false;
      final target = params['target'] as String?;
      final dartDefine = (params['dartDefine'] as Map?)?.cast<String, String>() ?? <String, String>{};

      await progressNotifier?.notify(message: 'Preparing build for $platform...', percent: 10);

      final args = <String>['build', platform];

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
      if (platform == 'android') {
        final buildMode = release ? 'release' : profile ? 'profile' : 'debug';
        buildPath = 'build/app/outputs/flutter-apk/app-$buildMode.apk';
      } else if (platform == 'ios') {
        buildPath = 'build/ios/iphoneos/Runner.app';
      } else if (platform == 'web') {
        buildPath = 'build/web';
      } else {
        buildPath = 'build/$platform';
      }

      return {
        'success': exitCode == 0,
        'exitCode': exitCode,
        'buildPath': buildPath,
        'logResourceUri': 'logs://build/$buildId',
        'message': exitCode == 0
            ? 'Build completed successfully'
            : 'Build failed with exit code $exitCode',
      };
    };
  }
}

