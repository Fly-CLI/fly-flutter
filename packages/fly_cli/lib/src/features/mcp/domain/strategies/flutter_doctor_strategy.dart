import 'dart:async';
import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/features/mcp/domain/mcp_tool_strategy.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for flutter.doctor tool
class FlutterDoctorStrategy extends McpToolStrategy {
  @override
  String get name => 'flutter.doctor';

  @override
  String get description => 'Run flutter doctor -v and return summarized output';

  @override
  Map<String, Object?> get paramsSchema => {
        'type': 'object',
        'properties': {},
        'additionalProperties': false,
      };

  @override
  Map<String, Object?> get resultSchema => {
        'type': 'object',
        'properties': {
          'stdout': {'type': 'string'},
          'exitCode': {'type': 'integer'},
        },
        'required': ['stdout', 'exitCode'],
      };

  @override
  bool get readOnly => false;

  @override
  bool get writesToDisk => false;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  ToolHandler createHandler(
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
      final truncated = combined.length > 8000 ? combined.substring(0, 8000) : combined;
      return {
        'stdout': truncated,
        'exitCode': code,
      };
    };
  }
}

