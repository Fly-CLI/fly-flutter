import 'dart:async';
import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_doctor_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/flutter_doctor_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.doctor tool
class FlutterDoctorStrategy
    extends McpToolStrategy<FlutterDoctorParams, FlutterDoctorResult> {
  @override
  String get name => 'flutter.doctor';

  @override
  String get description => 'Run flutter doctor -v and return summarized output';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {},
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'stdout': Schema.string(),
          'exitCode': Schema.int(),
        },
        required: ['stdout', 'exitCode'],
      );

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  FlutterDoctorParams paramsFromJson(Map<String, Object?> json) {
    return FlutterDoctorParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlutterDoctorParams, FlutterDoctorResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();
      await progressNotifier?.notify(message: 'Starting flutter doctor...');

      final proc = await Process.start('flutter', ['doctor', '-v']);

      // Monitor cancellation and process
      final completer = Completer<void>();
      cancelToken?.onCancel.then((_) {
        if (!completer.isCompleted) {
          proc.kill();
          completer.complete();
        }
      });

      final out = await proc.stdout.transform(const SystemEncoding().decoder).join();
      final err = await proc.stderr.transform(const SystemEncoding().decoder).join();
      final code = await proc.exitCode;

      cancelToken?.throwIfCancelled();

      final combined = out + (err.isEmpty ? '' : '\n$err');
      final truncated =
          combined.length > 8000 ? combined.substring(0, 8000) : combined;
      return FlutterDoctorResult(
        stdout: truncated,
        exitCode: code,
      );
    };
  }
}


