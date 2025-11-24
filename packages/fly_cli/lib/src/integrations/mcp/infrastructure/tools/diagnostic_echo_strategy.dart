import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/integrations/mcp/application/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/echo_params.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/types/echo_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.echo tool
class DiagnosticEchoStrategy extends McpToolStrategy<EchoParams, EchoResult> {
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
  EchoParams paramsFromJson(Map<String, Object?> json) {
    return EchoParams.fromJson(json);
  }

  @override
  TypedToolHandler<EchoParams, EchoResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();
      return EchoResult(message: params.message);
    };
  }
}

