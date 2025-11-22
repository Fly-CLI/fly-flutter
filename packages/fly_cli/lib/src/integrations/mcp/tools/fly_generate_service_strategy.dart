import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/generation/component_generation_service.dart';
import 'package:fly_cli/src/core/templates/generation/generation_adapter.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_generate_service_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_generate_service_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.generate.service tool
class FlyGenerateServiceStrategy extends McpToolStrategy<
    FlyGenerateServiceParams, FlyGenerateServiceResult> {
  @override
  String get name => 'fly.generate.service';

  @override
  String get description =>
      'Generate a new service component to the current project';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'serviceName': Schema.string(),
          'feature': Schema.string(),
          'serviceType': Schema.string(
              enumValues: ['api', 'local', 'cache', 'analytics', 'storage']),
          'withTests': Schema.bool(),
          'withMocks': Schema.bool(),
          'withInterceptors': Schema.bool(),
          'baseUrl': Schema.string(),
        },
        required: ['serviceName'],
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'message': Schema.string(),
          'filesGenerated': Schema.int(),
          'servicePath': Schema.string(),
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
  Duration? get timeout => const Duration(minutes: 2);

  @override
  FlyGenerateServiceParams paramsFromJson(Map<String, Object?> json) {
    return FlyGenerateServiceParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyGenerateServiceParams, FlyGenerateServiceResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      if (params.serviceName.isEmpty) {
        return FlyGenerateServiceResult(
          success: false,
          message: 'Missing required parameter: serviceName',
        );
      }

      // Convert MCP params to generation request using adapter
      final request = GenerationAdapter.fromMcpServiceParams(
        params: params,
        outputDirectory: Directory.current.path,
        context: context,
      );

      // Create unified generation service
      final generationService = ComponentGenerationService(context: context);

      // Generate service using unified service
      final result = await generationService.generateService(
        request: request,
        progressNotifier: progressNotifier,
      );

      cancelToken?.throwIfCancelled();

      if (!result.success) {
        return FlyGenerateServiceResult(
          success: false,
          message: 'Failed to generate service: ${result.error ?? 'Unknown error'}',
        );
      }

      return FlyGenerateServiceResult(
        success: true,
        message: 'Service generated successfully',
        filesGenerated: result.filesGenerated,
        servicePath: result.targetDirectory ?? Directory.current.path,
      );
    };
  }
}
