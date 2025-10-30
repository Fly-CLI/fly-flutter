import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/features/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_echo_params.dart';
import 'package:fly_cli/src/features/mcp/tools/types/fly_echo_result.dart';
import 'package:fly_mcp_server/fly_mcp_server.dart';

/// Strategy for fly.echo tool
class FlyEchoStrategy extends McpToolStrategy<FlyEchoParams, FlyEchoResult> {
  @override
  String get name => 'fly.echo';

  @override
  String get description => 'Echo back the provided message (diagnostic)';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'message': Schema.string(),
        },
        required: ['message'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'message': Schema.string(),
        },
        required: ['message'],
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
  FlyEchoParams paramsFromJson(Map<String, Object?> json) {
    return FlyEchoParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyEchoParams, FlyEchoResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();
      return FlyEchoResult(message: params.message);
    };
  }
}

