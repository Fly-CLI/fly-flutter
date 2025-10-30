import 'dart:async';
import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_run_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_run_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.run tool
class FlutterRunStrategy
    extends McpToolStrategy<FlutterRunParams, FlutterRunResult> {
  @override
  String get name => 'flutter.run';

  @override
  String get description => 'Run the current Flutter app';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'deviceId': Schema.string(),
          'debug': Schema.bool(),
          'release': Schema.bool(),
          'profile': Schema.bool(),
          'target': Schema.string(),
          'dartDefine': ObjectSchema(
            additionalProperties: Schema.string(),
          ),
        },
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'exitCode': Schema.int(),
          'processId': Schema.string(),
          'logResourceUri': Schema.string(),
          'message': Schema.string(),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => false;

  @override
  Duration? get timeout => const Duration(hours: 1);

  @override
  int? get maxConcurrency => 2;

  @override
  FlutterRunParams paramsFromJson(Map<String, Object?> json) {
    return FlutterRunParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlutterRunParams, FlutterRunResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      await progressNotifier?.notify(message: 'Starting Flutter app...');

      final release = params.release ?? false;
      final profile = params.profile ?? false;
      final deviceId = params.deviceId;
      final target = params.target;
      final dartDefine = params.dartDefine ?? <String, String>{};

      final args = <String>['run'];

      if (release) {
        args.add('--release');
      } else if (profile) {
        args.add('--profile');
      } else {
        args.add('--debug');
      }

      if (deviceId != null && deviceId.isNotEmpty) {
        args.addAll(['-d', deviceId]);
      }

      if (target != null && target.isNotEmpty) {
        args.add(target);
      }

      // Add dart-define arguments
      for (final entry in dartDefine.entries) {
        args.addAll(['--dart-define', '${entry.key}=${entry.value}']);
      }

      await progressNotifier?.notify(message: 'Launching app...', percent: 30);

      // Start the process
      final proc = await Process.start('flutter', args);

      // Generate a unique process ID for tracking
      final processId = 'flutter_run_${DateTime.now().microsecondsSinceEpoch}';

      // Monitor cancellation
      cancelToken?.onCancel.then((_) {
        try {
          proc.kill();
        } catch (_) {
          // Ignore errors if process already terminated
        }
      });

      // Start reading output in background and store in log resource
      final outputBuffer = StringBuffer();
      final errorBuffer = StringBuffer();

      // Get log provider from resource registry (capture in closure)
      final logProvider = resourceRegistry.logProvider;
      if (logProvider == null) {
        throw StateError('LogResourceProvider not found in ResourceRegistry');
      }

      proc.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
        outputBuffer.write(chunk);
        logProvider.storeRunLog(processId, chunk);
      });

      proc.stderr.transform(const SystemEncoding().decoder).listen((chunk) {
        errorBuffer.write(chunk);
        logProvider.storeRunLog(processId, chunk);
      });

      await progressNotifier?.notify(message: 'App running...', percent: 60);

      // Wait a short time for the process to start
      await Future<void>.delayed(const Duration(milliseconds: 500));

      cancelToken?.throwIfCancelled();

      // Return immediately with process info (async execution)
      return FlutterRunResult(
        success: true,
        processId: processId,
        logResourceUri: 'logs://run/$processId',
        message:
            'Flutter app launched successfully. Use logs://run/$processId to view output.',
        exitCode: 0, // Will be updated when process completes
      );
    };
  }
}



