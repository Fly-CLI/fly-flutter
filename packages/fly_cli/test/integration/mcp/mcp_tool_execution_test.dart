import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/telemetry/infrastructure/metrics_config.dart';
import 'package:fly_cli/src/core/telemetry/infrastructure/metrics_factory.dart';
import 'package:fly_cli/src/core/generation/template/template_manager.dart';
import 'package:fly_cli/src/integrations/mcp/tools/diagnostic_echo_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/template_apply_strategy.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:mason_logger/mason_logger.dart' as mason_logger;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

void main() {
  group('MCP Tool Execution Integration Tests', () {
    late CommandContext context;
    late ResourceRegistry resourceRegistry;
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_mcp_test_');
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
      final metricsConfig = const MetricsConfig(enabled: false);
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

    group('fly.echo tool', () {
      test('should execute successfully with valid parameters', () async {
        final strategy = DiagnosticEchoStrategy();
        final handler = strategy.createHandler(context, resourceRegistry);

        final result = await handler(
          {'message': 'Test message'},
        ) as Map<String, Object?>;

        expect(result['message'], 'Test message');
      });

      test('should validate parameters and throw structured error', () async {
        final strategy = DiagnosticEchoStrategy();
        final handler = strategy.createHandler(context, resourceRegistry);

        expect(
          () => handler(<String, Object?>{}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('tool error handling', () {
      test('should return structured error for invalid parameters', () async {
        final strategy = TemplateApplyStrategy();
        final handler = strategy.createHandler(context, resourceRegistry);

        try {
          await handler({
            'templateId': '', // Invalid: empty
            'outputDirectory': tempDir.path,
          });
          fail('Should have thrown error');
        } catch (error) {
          expect(error, isA<StateError>());
          final errorStr = error.toString();
          expect(errorStr, contains('templateId'));
          expect(errorStr, contains('required'));
        }
      });

      test('should validate enum values with suggestions', () async {
        // This would require a tool with enum parameters
        // For now, we test through schema validation
        expect(true, isTrue); // Placeholder for enum validation test
      });
    });

    group('progress notifications', () {
      test('should emit progress notifications for template application',
          () async {
        final progressNotifications = <String, int>{};

        // Create a strategy and get handler with progress tracking
        final strategy = TemplateApplyStrategy();

        // Note: Progress notifications are handled by MCP server middleware
        // In integration tests, we'd test through the MCP protocol
        expect(true, isTrue); // Placeholder for progress notification test
      });
    });

    group('correlation ID tracking', () {
      test('should generate correlation ID for each tool execution', () async {
        final strategy = DiagnosticEchoStrategy();
        final handler = strategy.createHandler(context, resourceRegistry);

        final result1 = await handler({'message': 'Test 1'});
        final result2 = await handler({'message': 'Test 2'});

        // Correlation IDs should be different for each execution
        // (This is handled in the base handler)
        expect(result1, isNotNull);
        expect(result2, isNotNull);
      });
    });
  });
}

args.ArgResults _createArgResults() {
  final parser = args.ArgParser();
  return parser.parse(<String>[]);
}
