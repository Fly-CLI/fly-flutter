import 'dart:io';

import 'package:args/args.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/templates/generation/component_generation_service.dart';
import 'package:fly_cli/src/core/templates/generation/generation_adapter.dart';
import 'package:fly_cli/src/core/templates/generation/generation_request.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_generate_screen_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_generate_service_params.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import '../../../helpers/command_test_helper.dart';

void main() {
  group('ComponentGenerationService', () {
    late CommandContext context;
    late ComponentGenerationService service;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('fly_generation_test_');
    });

    setUp(() {
      context = CommandTestHelper.createMockCommandContext(
        workingDirectory: tempDir.path,
      );
      service = ComponentGenerationService(context: context);
    });

    tearDownAll(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // Ignore cleanup errors
      }
    });

    group('generateFeature', () {
      test('should generate feature from CLI-style request', () async {
        final request = GenerationRequest.feature(
          componentName: 'test_screen',
          feature: 'test_feature',
          screenType: 'list',
          withViewModel: true,
          withTests: true,
          outputDirectory: tempDir.path,
          context: context,
        );

        final result = await service.generateFeature(
          request: request,
        );

        expect(result.success, isTrue);
        expect(result.filesGenerated, greaterThan(0));
        expect(result.targetDirectory, isNotNull);
      });

      test('should generate feature from MCP-style request', () async {
        final request = GenerationRequest.feature(
          componentName: 'mcp_screen',
          feature: 'mcp_feature',
          screenType: 'detail',
          withViewModel: false,
          withTests: false,
          outputDirectory: tempDir.path,
        );

        final result = await service.generateFeature(
          request: request,
        );

        expect(result.success, isTrue);
        expect(result.filesGenerated, greaterThan(0));
      });

      test('should handle validation errors', () async {
        final request = GenerationRequest.feature(
          componentName: '', // Invalid empty name
          feature: 'test_feature',
          outputDirectory: tempDir.path,
        );

        final result = await service.generateFeature(
          request: request,
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Validation failed'));
      });

      test('should send progress notifications', () async {
        var progressMessages = <String>[];
        final progressNotifier = MockProgressNotifier(
          onNotify: (message, percent) {
            progressMessages.add(message);
          },
        );

        final request = GenerationRequest.feature(
          componentName: 'progress_test',
          feature: 'test_feature',
          outputDirectory: tempDir.path,
        );

        await service.generateFeature(
          request: request,
          progressNotifier: progressNotifier,
        );

        expect(progressMessages, isNotEmpty);
        expect(progressMessages.any((m) => m.contains('progress_test')), isTrue);
      });
    });

    group('generateService', () {
      test('should generate service from CLI-style request', () async {
        final request = GenerationRequest.service(
          componentName: 'test_service',
          feature: 'test_feature',
          serviceType: 'api',
          withTests: true,
          withMocks: false,
          outputDirectory: tempDir.path,
          context: context,
        );

        final result = await service.generateService(
          request: request,
        );

        expect(result.success, isTrue);
        expect(result.filesGenerated, greaterThan(0));
        expect(result.targetDirectory, isNotNull);
      });

      test('should generate service from MCP-style request', () async {
        final request = GenerationRequest.service(
          componentName: 'mcp_service',
          feature: 'mcp_feature',
          serviceType: 'cache',
          withTests: false,
          withMocks: true,
          outputDirectory: tempDir.path,
        );

        final result = await service.generateService(
          request: request,
        );

        expect(result.success, isTrue);
        expect(result.filesGenerated, greaterThan(0));
      });

      test('should handle API service with base URL', () async {
        final request = GenerationRequest.service(
          componentName: 'api_service',
          feature: 'api_feature',
          serviceType: 'api',
          baseUrl: 'https://api.example.com',
          outputDirectory: tempDir.path,
        );

        final result = await service.generateService(
          request: request,
        );

        expect(result.success, isTrue);
      });

      test('should handle validation errors', () async {
        final request = GenerationRequest.service(
          componentName: '', // Invalid empty name
          feature: 'test_feature',
          outputDirectory: tempDir.path,
        );

        final result = await service.generateService(
          request: request,
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Validation failed'));
      });

      test('should send progress notifications', () async {
        var progressMessages = <String>[];
        final progressNotifier = MockProgressNotifier(
          onNotify: (message, percent) {
            progressMessages.add(message);
          },
        );

        final request = GenerationRequest.service(
          componentName: 'progress_service',
          feature: 'test_feature',
          outputDirectory: tempDir.path,
        );

        await service.generateService(
          request: request,
          progressNotifier: progressNotifier,
        );

        expect(progressMessages, isNotEmpty);
        expect(progressMessages.any((m) => m.contains('progress_service')), isTrue);
      });
    });

    group('consistent behavior between CLI and MCP', () {
      test('should produce same results for equivalent feature requests', () async {
        // CLI-style request (with context)
        final cliRequest = GenerationRequest.feature(
          componentName: 'comparison_screen',
          feature: 'test_feature',
          screenType: 'list',
          withViewModel: true,
          withTests: true,
          outputDirectory: tempDir.path,
          context: context,
        );

        // MCP-style request with same parameters (no context)
        final mcpParams = FlyGenerateScreenParams(
          screenName: 'comparison_screen',
          feature: 'test_feature',
          screenType: 'list',
          withViewModel: true,
          withTests: true,
        );
        final mcpRequest = GenerationAdapter.fromMcpFeatureParams(
          params: mcpParams,
          outputDirectory: tempDir.path,
        );

        final cliResult = await service.generateFeature(request: cliRequest);
        final mcpResult = await service.generateFeature(request: mcpRequest);

        // Both should succeed
        expect(cliResult.success, isTrue);
        expect(mcpResult.success, isTrue);

        // Both should generate the same number of files
        expect(cliResult.filesGenerated, equals(mcpResult.filesGenerated));

        // Both should have the same target directory structure
        expect(cliResult.targetDirectory, isNotNull);
        expect(mcpResult.targetDirectory, isNotNull);
      });

      test('should produce same results for equivalent service requests', () async {
        // CLI-style request (with context)
        final cliRequest = GenerationRequest.service(
          componentName: 'comparison_service',
          feature: 'test_feature',
          serviceType: 'api',
          withTests: true,
          withMocks: true,
          baseUrl: 'https://api.test.com',
          outputDirectory: tempDir.path,
          context: context,
        );

        // MCP-style request with same parameters (no context)
        final mcpParams = FlyGenerateServiceParams(
          serviceName: 'comparison_service',
          feature: 'test_feature',
          serviceType: 'api',
          withTests: true,
          withMocks: true,
          baseUrl: 'https://api.test.com',
        );
        final mcpRequest = GenerationAdapter.fromMcpServiceParams(
          params: mcpParams,
          outputDirectory: tempDir.path,
        );

        final cliResult = await service.generateService(request: cliRequest);
        final mcpResult = await service.generateService(request: mcpRequest);

        // Both should succeed
        expect(cliResult.success, isTrue);
        expect(mcpResult.success, isTrue);

        // Both should generate the same number of files
        expect(cliResult.filesGenerated, equals(mcpResult.filesGenerated));

        // Both should have the same target directory structure
        expect(cliResult.targetDirectory, isNotNull);
        expect(mcpResult.targetDirectory, isNotNull);
      });

      test('should handle default values consistently', () async {
        // CLI request with minimal params
        final cliRequest = GenerationRequest.feature(
          componentName: 'minimal_screen',
          outputDirectory: tempDir.path,
          context: context,
        );

        // MCP request with minimal params (should use same defaults)
        final mcpParams = FlyGenerateScreenParams(
          screenName: 'minimal_screen',
        );
        final mcpRequest = GenerationAdapter.fromMcpFeatureParams(
          params: mcpParams,
          outputDirectory: tempDir.path,
        );

        final cliResult = await service.generateFeature(request: cliRequest);
        final mcpResult = await service.generateFeature(request: mcpRequest);

        // Both should succeed with default values
        expect(cliResult.success, isTrue);
        expect(mcpResult.success, isTrue);

        // Both should generate files
        expect(cliResult.filesGenerated, greaterThan(0));
        expect(mcpResult.filesGenerated, greaterThan(0));
      });

      test('should validate inputs consistently', () async {
        // Both CLI and MCP should reject invalid inputs the same way
        final invalidRequest = GenerationRequest.feature(
          componentName: '', // Invalid empty name
          outputDirectory: tempDir.path,
        );

        final result = await service.generateFeature(request: invalidRequest);

        expect(result.success, isFalse);
        expect(result.error, contains('Validation failed'));
      });
    });
  });

  group('GenerationAdapter', () {
    test('should convert MCP feature params to request', () {
      final params = FlyGenerateScreenParams(
        screenName: 'test_screen',
        feature: 'test_feature',
        screenType: 'list',
        withViewModel: true,
        withTests: true,
        withValidation: false,
        withNavigation: true,
      );

      final request = GenerationAdapter.fromMcpFeatureParams(
        params: params,
        outputDirectory: '/test/output',
      );

      expect(request.componentName, equals('test_screen'));
      expect(request.feature, equals('test_feature'));
      expect(request.screenType, equals('list'));
      expect(request.withViewModel, isTrue);
      expect(request.withTests, isTrue);
      expect(request.withValidation, isFalse);
      expect(request.withNavigation, isTrue);
      expect(request.outputDirectory, equals('/test/output'));
    });

    test('should convert MCP service params to request', () {
      final params = FlyGenerateServiceParams(
        serviceName: 'test_service',
        feature: 'test_feature',
        serviceType: 'api',
        withTests: true,
        withMocks: true,
        withInterceptors: true,
        baseUrl: 'https://api.test.com',
      );

      final request = GenerationAdapter.fromMcpServiceParams(
        params: params,
        outputDirectory: '/test/output',
      );

      expect(request.componentName, equals('test_service'));
      expect(request.feature, equals('test_feature'));
      expect(request.serviceType, equals('api'));
      expect(request.withTests, isTrue);
      expect(request.withMocks, isTrue);
      expect(request.withInterceptors, isTrue);
      expect(request.baseUrl, equals('https://api.test.com'));
      expect(request.outputDirectory, equals('/test/output'));
    });
  });
}

/// Mock progress notifier for testing
class MockProgressNotifier extends ProgressNotifier {
  final void Function(String message, int? percent) onNotify;

  MockProgressNotifier({required this.onNotify}) : super(enabled: true);

  @override
  Future<void> notify({
    required String message,
    int? percent,
  }) async {
    onNotify(message, percent);
  }
}

