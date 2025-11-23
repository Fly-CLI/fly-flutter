import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/integrations/mcp/adapters/generation_mcp_adapter.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/generate_service_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/generate_service_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.generate.service tool
class GenerateServiceStrategy extends McpToolStrategy<
    GenerateServiceParams, GenerateServiceResult> {
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
  GenerateServiceParams paramsFromJson(Map<String, Object?> json) {
    return GenerateServiceParams.fromJson(json);
  }

  @override
  TypedToolHandler<GenerateServiceParams, GenerateServiceResult>
      createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      if (params.serviceName.isEmpty) {
        return GenerateServiceResult(
          success: false,
          message: 'Missing required parameter: serviceName',
        );
      }

      // Convert MCP params to raw variables
      final rawVars = <String, dynamic>{
        'name': params.serviceName,
        'generation_mode': 'service',
        'feature': params.feature ?? 'core',
        'service_type': params.serviceType ?? 'api',
        'with_tests': params.withTests ?? true,
        'with_mocks': params.withMocks ?? false,
        'with_interceptors': params.withInterceptors ?? false,
        if (params.baseUrl != null) 'api_base_url': params.baseUrl,
      };

      // Get MCP adapter from service container
      final adapter = context.getService<GenerationMcpAdapter>();

      // Generate service
      final result = await adapter.generateService(
        serviceName: params.serviceName,
        feature: params.feature,
        serviceType: params.serviceType,
        withTests: params.withTests,
        withMocks: params.withMocks,
        withInterceptors: params.withInterceptors,
        baseUrl: params.baseUrl,
        outputDirectory: Directory.current.path,
      );

      cancelToken?.throwIfCancelled();

      if (!result.success) {
        return GenerateServiceResult(
          success: false,
          message: 'Failed to generate service: ${result.error ?? 'Unknown error'}',
        );
      }

      return GenerateServiceResult(
        success: true,
        message: 'Service generated successfully',
        filesGenerated: result.generatedFiles.length,
        servicePath: Directory.current.path,
      );
    };
  }
}


