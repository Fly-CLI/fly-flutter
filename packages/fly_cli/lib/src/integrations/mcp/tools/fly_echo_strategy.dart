import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_echo_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_echo_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.echo tool
class FlyEchoStrategy extends McpToolStrategy<FlyEchoParams, FlyEchoResult> {
  @override
  String get name => 'fly.echo';

  @override
  String get description =>
      'Echo back the provided message. Used for diagnostic purposes to test MCP server connectivity and basic functionality.';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        description:
            'Parameters for echo tool - used to test MCP server connectivity',
        properties: {
          'message': Schema.string(
            description: 'The message to echo back. Can be any string value.',
          ),
        },
        required: ['message'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        description: 'Result from echo tool - contains the echoed message',
        properties: {
          'message': Schema.string(
            description:
                'The same message that was provided as input, echoed back',
          ),
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
