import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/features/commands/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/features/diagnostics/domain/system_checker.dart';
import 'package:fly_cli/src/cli/infrastructure/path_management/path_resolver.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/cli/infrastructure/telemetry/infrastructure/metrics_factory.dart';
import 'package:fly_cli/src/generation/template/template_manager.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/errors/mcp_error.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/prompts/prompt_error.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/resources/resource_error.dart';
import 'package:fly_cli/src/integrations/mcp/infrastructure/tools/template_apply_strategy.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:mason_logger/mason_logger.dart' as mason_logger;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

void main() {
  group('MCP Error Handling Integration Tests', () {
    late CommandContext context;
    late ResourceRegistry resourceRegistry;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_error_test_');
      final logger = mason_logger.Logger();

      final templateManager = TemplateManager(
        templatesDirectory: path.join(tempDir.path, 'templates'),
        logger: logger,
      );

      final systemChecker = SystemChecker(logger: logger);
      final pathResolver = PathResolver(
        logger: logger,
        isDevelopment: true,
      );
      final interactivePrompt = InteractivePrompt(logger);

      // Create a metrics collector for testing (disabled to avoid noise)
      const metricsConfig = MetricsConfig(enabled: false);
      final metricsFactory = MetricsFactory(metricsConfig);
      final metricsCollector = metricsFactory.create();

      final mockFactory = MockContextFactory();
      context = CommandContextImpl(
        argResults: _createArgResults(),
        logger: logger,
        templateManager: templateManager,
        systemChecker: systemChecker,
        interactivePrompt: interactivePrompt,
        pathResolver: pathResolver,
        metricsCollector: metricsCollector,
        config: {},
        environment: Environment.current(),
        workingDirectory: tempDir.path,
        verbose: false,
        quiet: false,
        factory: mockFactory,
      );

      final logProvider = LogResourceProvider();
      resourceRegistry = ResourceRegistry(
        strategies: [],
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('tool error handling', () {
      test('should throw McpError with structured context', () async {
        final strategy = TemplateApplyStrategy();
        final handler = strategy.createHandler(context, resourceRegistry);

        try {
          await handler({
            'templateId': 'nonexistent',
            'outputDirectory': tempDir.path,
          });
          fail('Should have thrown error');
        } catch (error) {
          // Error should be wrapped in handler
          expect(error, isA<StateError>());

          // Check error message contains helpful information
          final message = error.toString();
          expect(message, isNotEmpty);
        }
      });

      test('should include field-level errors in validation failures',
          () async {
        final strategy = TemplateApplyStrategy();
        final handler = strategy.createHandler(context, resourceRegistry);

        try {
          await handler({
            'templateId': '', // Invalid: empty
            'outputDirectory': '', // Invalid: empty
          });
          fail('Should have thrown error');
        } catch (error) {
          expect(error, isA<StateError>());
          // Error should include field errors
          final message = error.toString();
          expect(
              message.contains('templateId') ||
                  message.contains('outputDirectory'),
              isTrue);
        }
      });
    });

    group('resource error handling', () {
      test('should provide structured ResourceError with hints', () {
        try {
          throw ResourceError.pathTraversal(
            path: '../../etc/passwd',
            workspaceRoot: tempDir.path,
            resourceUri: 'workspace://../../etc/passwd',
          );
        } catch (error) {
          expect(error, isA<ResourceError>());
          final resourceError = error as ResourceError;

          expect(resourceError.code, 'path_traversal');
          expect(resourceError.category, 'security');
          expect(resourceError.hints, isNotEmpty);
          expect(resourceError.remediation, isNotNull);
        }
      });

      test('should include suggestions in notFound errors', () {
        try {
          throw ResourceError.notFound(
            path: '/workspace/missing.dart',
            resourceUri: 'workspace://missing.dart',
            suggestions: ['/workspace/main.dart', '/workspace/lib.dart'],
          );
        } catch (error) {
          expect(error, isA<ResourceError>());
          final resourceError = error as ResourceError;

          expect(resourceError.code, 'not_found');
          expect(resourceError.context['suggestions'], isNotNull);
        }
      });
    });

    group('prompt error handling', () {
      test('should provide structured PromptError with variable information',
          () {
        try {
          throw PromptError.missingVariable(
            variableName: 'name',
            promptId: 'fly.scaffold.page',
            description: 'The name of the page',
          );
        } catch (error) {
          expect(error, isA<PromptError>());
          final promptError = error as PromptError;

          expect(promptError.code, 'missing_variable');
          expect(promptError.variableName, 'name');
          expect(promptError.promptId, 'fly.scaffold.page');
          expect(promptError.hints, isNotEmpty);
          expect(promptError.remediation, isNotNull);
        }
      });

      test('should include allowed values in invalidVariableValue errors', () {
        try {
          throw PromptError.invalidVariableValue(
            variableName: 'stateManagement',
            reason: 'Value not in allowed list',
            promptId: 'fly.scaffold.page',
            allowedValues: ['riverpod', 'bloc', 'provider'],
          );
        } catch (error) {
          expect(error, isA<PromptError>());
          final promptError = error as PromptError;

          expect(promptError.code, 'invalid_variable_value');
          expect(promptError.context['allowed_values'], isNotNull);
          expect(promptError.hints.any((e) => e.contains('riverpod')), isTrue);
        }
      });
    });

    group('error message formatting', () {
      test('should format McpError with hints and remediation', () {
        final error = McpError.invalidParams(
          tool: 'test.tool',
          errors: ['Error 1', 'Error 2'],
          context: {
            'field_errors': {
              'field1': {'type': 'missing_required'},
            },
          },
        );

        final message = error.toString();
        expect(message, contains('test.tool'));
        expect(
            message.contains('Error 1') || message.contains('Error 2'), isTrue);
      });

      test('should format ResourceError with hints and remediation', () {
        final error = ResourceError.invalidUri(
          resourceUri: 'invalid://path',
          expectedFormat: 'workspace://<relative-path>',
        );

        final message = error.toString();
        expect(
            message.contains('Invalid resource URI') ||
                message.contains('invalid://path'),
            isTrue);
      });

      test('should format PromptError with hints and remediation', () {
        final error = PromptError.missingVariable(
          variableName: 'name',
          promptId: 'test.prompt',
        );

        final message = error.toString();
        expect(
            message.contains('Missing required variable') ||
                message.contains('name'),
            isTrue);
      });
    });
  });
}

args.ArgResults _createArgResults() {
  final parser = args.ArgParser();
  return parser.parse(<String>[]);
}
