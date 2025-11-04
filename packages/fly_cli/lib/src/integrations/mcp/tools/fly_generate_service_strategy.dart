import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
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

      final feature = params.feature ?? 'core';
      final serviceType = params.serviceType ?? 'api';
      final withTests = params.withTests ?? false;
      final withMocks = params.withMocks ?? false;
      final withInterceptors = params.withInterceptors ?? false;
      final baseUrl = params.baseUrl ?? 'https://api.example.com';

      await progressNotifier?.notify(
          message: 'Generating service: ${params.serviceName}...', percent: 10);

      final templateManager = context.templateManager;

      // Create service configuration for Mason brick
      final serviceConfig = <String, dynamic>{
        'service_name': params.serviceName,
        'feature': feature,
        'service_type': serviceType,
        'with_tests': withTests,
        'with_mocks': withMocks,
        'with_interceptors': withInterceptors,
        'base_url': baseUrl,
      };

      await progressNotifier?.notify(
          message: 'Generating service files...', percent: 50);

      // Generate service using TemplateManager
      final result = await templateManager.generateComponent(
        componentName: params.serviceName,
        componentType: BrickType.service,
        config: serviceConfig,
        targetPath: Directory.current.path,
      );

      cancelToken?.throwIfCancelled();

      if (result is TemplateGenerationFailure) {
        return FlyGenerateServiceResult(
          success: false,
          message: 'Failed to generate service: ${result.error}',
        );
      }

      if (result is! TemplateGenerationSuccess) {
        return FlyGenerateServiceResult(
          success: false,
          message: 'Unexpected generation result',
        );
      }

      return FlyGenerateServiceResult(
        success: true,
        message: 'Service generated successfully',
        filesGenerated: result.filesGenerated,
        servicePath: result.targetDirectory,
      );
    };
  }
}
